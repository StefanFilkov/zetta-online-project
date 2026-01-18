package com.microservices.order.service;

import com.microservices.order.client.InventoryClient;
import com.microservices.order.dto.*;
import com.microservices.order.entity.Order;
import com.microservices.order.entity.OrderItem;
import com.microservices.order.exception.InsufficientStockException;
import com.microservices.order.exception.OrderCreationException;
import com.microservices.order.exception.ProductNotFoundException;
import com.microservices.order.repository.OrderRepository;
import feign.FeignException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final InventoryClient inventoryClient;

    @Transactional
    public OrderResponse createOrder(OrderRequest orderRequest) {
        log.info("Creating order for product ID: {} with quantity: {}",
                orderRequest.getProductId(), orderRequest.getQuantity());

        try {
            // Step 1: Fetch product details from Inventory Service
            ProductResponse product = inventoryClient.getProductById(orderRequest.getProductId());
            log.info("Product fetched: {} with stock: {}", product.getName(), product.getStockQuantity());

            // Step 2: Validate stock availability
            if (!product.isInStock() || product.getStockQuantity() < orderRequest.getQuantity()) {
                log.warn("Insufficient stock for product: {}. Available: {}, Requested: {}",
                        product.getName(), product.getStockQuantity(), orderRequest.getQuantity());
                throw new InsufficientStockException(
                        "Insufficient stock. Available: " + product.getStockQuantity() + ", Requested: " + orderRequest.getQuantity());
            }

            // Step 3: Reduce stock in Inventory Service
            ReduceStockRequest reduceStockRequest = ReduceStockRequest.builder()
                    .productId(orderRequest.getProductId())
                    .quantity(orderRequest.getQuantity())
                    .build();

            StockResponse stockResponse = inventoryClient.reduceStock(reduceStockRequest);
            log.info("Stock reduced successfully. Remaining stock: {}", stockResponse.getRemainingStock());

            // Step 4: Create order
            Order order = createOrderEntity(orderRequest, product);
            Order savedOrder = orderRepository.save(order);
            log.info("Order created successfully with order number: {}", savedOrder.getOrderNumber());

            return mapToOrderResponse(savedOrder, "Order placed successfully!");

        } catch (FeignException.NotFound e) {
            log.error("Product not found with ID: {}", orderRequest.getProductId());
            throw new ProductNotFoundException("Product not found with ID: " + orderRequest.getProductId());
        } catch (FeignException.BadRequest e) {
            log.error("Bad request while communicating with Inventory Service: {}", e.getMessage());
            throw new InsufficientStockException("Unable to process order due to stock issues");
        } catch (FeignException e) {
            log.error("Error communicating with Inventory Service: {}", e.getMessage());
            throw new OrderCreationException("Failed to create order. Please try again later.");
        }
    }

    @Transactional(readOnly = true)
    public List<OrderResponse> getAllOrders() {
        log.info("Fetching all orders");
        return orderRepository.findAll().stream()
                .map(order -> mapToOrderResponse(order, null))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public OrderResponse getOrderById(Long id) {
        log.info("Fetching order with ID: {}", id);
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new OrderCreationException("Order not found with ID: " + id));
        return mapToOrderResponse(order, null);
    }

    private Order createOrderEntity(OrderRequest orderRequest, ProductResponse product) {
        BigDecimal unitPrice = product.getPrice();
        BigDecimal totalPrice = unitPrice.multiply(BigDecimal.valueOf(orderRequest.getQuantity()));

        OrderItem orderItem = OrderItem.builder()
                .productId(product.getId())
                .productName(product.getName())
                .quantity(orderRequest.getQuantity())
                .unitPrice(unitPrice)
                .totalPrice(totalPrice)
                .build();

        Order order = Order.builder()
                .orderNumber(generateOrderNumber())
                .totalAmount(totalPrice)
                .status(Order.OrderStatus.CONFIRMED)
                .build();

        order.addOrderItem(orderItem);
        return order;
    }

    private String generateOrderNumber() {
        return "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    private OrderResponse mapToOrderResponse(Order order, String message) {
        List<OrderItemResponse> items = order.getOrderItems().stream()
                .map(item -> OrderItemResponse.builder()
                        .productId(item.getProductId())
                        .productName(item.getProductName())
                        .quantity(item.getQuantity())
                        .unitPrice(item.getUnitPrice())
                        .totalPrice(item.getTotalPrice())
                        .build())
                .collect(Collectors.toList());

        return OrderResponse.builder()
                .id(order.getId())
                .orderNumber(order.getOrderNumber())
                .items(items)
                .totalAmount(order.getTotalAmount())
                .status(order.getStatus().name())
                .createdAt(order.getCreatedAt())
                .message(message)
                .build();
    }
}
