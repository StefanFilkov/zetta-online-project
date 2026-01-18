package com.microservices.order.client;

import com.microservices.order.dto.ProductResponse;
import com.microservices.order.dto.ReduceStockRequest;
import com.microservices.order.dto.StockResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

@FeignClient(name = "inventory-service", url = "${inventory.service.url}")
public interface InventoryClient {

    @GetMapping("/api/products/{id}")
    ProductResponse getProductById(@PathVariable("id") Long id);

    @PostMapping("/api/products/reduce-stock")
    StockResponse reduceStock(@RequestBody ReduceStockRequest request);
}
