package com.microservices.inventory.config;

import com.microservices.inventory.entity.Product;
import com.microservices.inventory.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final ProductRepository productRepository;

    @Override
    public void run(String... args) {
        if (productRepository.count() == 0) {
            log.info("Initializing sample products...");

            List<Product> products = Arrays.asList(
                    Product.builder()
                            .name("Laptop")
                            .description("High-performance laptop with 16GB RAM and 512GB SSD")
                            .price(new BigDecimal("1299.99"))
                            .stockQuantity(15)
                            .imageUrl("https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400")
                            .build(),

                    Product.builder()
                            .name("Wireless Mouse")
                            .description("Ergonomic wireless mouse with precision tracking")
                            .price(new BigDecimal("29.99"))
                            .stockQuantity(50)
                            .imageUrl("https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=400")
                            .build(),

                    Product.builder()
                            .name("Mechanical Keyboard")
                            .description("RGB mechanical keyboard with Cherry MX switches")
                            .price(new BigDecimal("89.99"))
                            .stockQuantity(30)
                            .imageUrl("https://images.unsplash.com/photo-1595225476474-87563907a212?w=400")
                            .build(),

                    Product.builder()
                            .name("USB-C Hub")
                            .description("7-in-1 USB-C hub with HDMI, USB 3.0, and SD card reader")
                            .price(new BigDecimal("49.99"))
                            .stockQuantity(40)
                            .imageUrl("https://images.unsplash.com/photo-1625948515291-69613efd103f?w=400")
                            .build(),

                    Product.builder()
                            .name("Monitor 27\"")
                            .description("4K UHD monitor with 144Hz refresh rate")
                            .price(new BigDecimal("399.99"))
                            .stockQuantity(20)
                            .imageUrl("https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=400")
                            .build(),

                    Product.builder()
                            .name("Webcam HD")
                            .description("1080p HD webcam with built-in microphone")
                            .price(new BigDecimal("79.99"))
                            .stockQuantity(25)
                            .imageUrl("https://images.unsplash.com/photo-1589792923962-537704632910?w=400")
                            .build()
            );

            productRepository.saveAll(products);
            log.info("Sample products initialized successfully. Total products: {}", products.size());
        } else {
            log.info("Products already exist in database. Skipping initialization.");
        }
    }
}
