package com.microservices.inventory.controller;

import com.microservices.inventory.dto.ProductResponse;
import com.microservices.inventory.dto.ReduceStockRequest;
import com.microservices.inventory.dto.StockResponse;
import com.microservices.inventory.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
@Tag(name = "Product Management", description = "APIs for managing product inventory")
@CrossOrigin(origins = "*")
public class ProductController {

    private final ProductService productService;

    @GetMapping
    @Operation(summary = "Get all products", description = "Retrieve a list of all products with their stock information")
    public ResponseEntity<List<ProductResponse>> getAllProducts() {
        List<ProductResponse> products = productService.getAllProducts();
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get product by ID", description = "Retrieve detailed information about a specific product")
    public ResponseEntity<ProductResponse> getProductById(@PathVariable Long id) {
        ProductResponse product = productService.getProductById(id);
        return ResponseEntity.ok(product);
    }

    @PostMapping("/reduce-stock")
    @Operation(summary = "Reduce product stock", description = "Internal API to reduce stock quantity for a product")
    public ResponseEntity<StockResponse> reduceStock(@Valid @RequestBody ReduceStockRequest request) {
        StockResponse response = productService.reduceStock(request);
        return ResponseEntity.ok(response);
    }
}
