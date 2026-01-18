package com.microservices.inventory.service;

import com.microservices.inventory.dto.ProductResponse;
import com.microservices.inventory.dto.ReduceStockRequest;
import com.microservices.inventory.dto.StockResponse;
import com.microservices.inventory.entity.Product;
import com.microservices.inventory.exception.InsufficientStockException;
import com.microservices.inventory.exception.ProductNotFoundException;
import com.microservices.inventory.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProductService {

    private final ProductRepository productRepository;

    @Transactional(readOnly = true)
    public List<ProductResponse> getAllProducts() {
        log.info("Fetching all products");
        return productRepository.findAll().stream()
                .map(this::mapToProductResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ProductResponse getProductById(Long id) {
        log.info("Fetching product with id: {}", id);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with id: " + id));
        return mapToProductResponse(product);
    }

    @Transactional
    public StockResponse reduceStock(ReduceStockRequest request) {
        log.info("Reducing stock for product id: {} by quantity: {}", request.getProductId(), request.getQuantity());

        // Use pessimistic locking to prevent race conditions
        Product product = productRepository.findByIdWithLock(request.getProductId())
                .orElseThrow(() -> new ProductNotFoundException("Product not found with id: " + request.getProductId()));

        if (!product.hasStock(request.getQuantity())) {
            log.warn("Insufficient stock for product id: {}. Available: {}, Requested: {}",
                    request.getProductId(), product.getStockQuantity(), request.getQuantity());
            throw new InsufficientStockException(
                    "Insufficient stock. Available: " + product.getStockQuantity() + ", Requested: " + request.getQuantity());
        }

        product.reduceStock(request.getQuantity());
        Product savedProduct = productRepository.save(product);

        log.info("Stock reduced successfully for product id: {}. Remaining stock: {}",
                savedProduct.getId(), savedProduct.getStockQuantity());

        return StockResponse.builder()
                .success(true)
                .message("Stock reduced successfully")
                .remainingStock(savedProduct.getStockQuantity())
                .build();
    }

    private ProductResponse mapToProductResponse(Product product) {
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .description(product.getDescription())
                .price(product.getPrice())
                .stockQuantity(product.getStockQuantity())
                .imageUrl(product.getImageUrl())
                .inStock(product.getStockQuantity() > 0)
                .build();
    }
}
