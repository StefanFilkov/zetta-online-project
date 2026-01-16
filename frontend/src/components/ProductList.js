import React, { useState, useEffect } from 'react';
import ProductCard from './ProductCard';
import { inventoryService, orderService } from '../services/api';
import { toast } from 'react-toastify';
import './ProductList.css';

const ProductList = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await inventoryService.getAllProducts();
      setProducts(data);
    } catch (err) {
      setError('Failed to load products. Please try again later.');
      toast.error('Failed to load products');
    } finally {
      setLoading(false);
    }
  };

  const handleBuyNow = async (productId, quantity) => {
    try {
      const orderData = {
        productId: productId,
        quantity: quantity,
      };

      const response = await orderService.createOrder(orderData);

      toast.success(
        `Order placed successfully! Order Number: ${response.orderNumber}`,
        { autoClose: 5000 }
      );

      // Refresh products to update stock levels
      await fetchProducts();
    } catch (err) {
      const errorMessage = err.response?.data?.message || 'Failed to place order. Please try again.';
      toast.error(errorMessage);
    }
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>Loading products...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-container">
        <p className="error-message">{error}</p>
        <button onClick={fetchProducts} className="retry-btn">
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="product-list-container">
      <header className="page-header">
        <h1>Shop Dashboard</h1>
        <p>Browse our products and place your orders</p>
      </header>

      {products.length === 0 ? (
        <div className="empty-state">
          <p>No products available at the moment.</p>
        </div>
      ) : (
        <div className="product-grid">
          {products.map((product) => (
            <ProductCard
              key={product.id}
              product={product}
              onBuyNow={handleBuyNow}
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default ProductList;
