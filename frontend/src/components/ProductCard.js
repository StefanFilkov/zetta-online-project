import React, { useState } from 'react';
import './ProductCard.css';

const ProductCard = ({ product, onBuyNow }) => {
  const [quantity, setQuantity] = useState(1);
  const [loading, setLoading] = useState(false);

  const handleBuyClick = async () => {
    setLoading(true);
    try {
      await onBuyNow(product.id, quantity);
    } finally {
      setLoading(false);
      setQuantity(1); // Reset quantity after purchase
    }
  };

  return (
    <div className="product-card">
      <div className="product-image">
        <img src={product.imageUrl} alt={product.name} />
        {!product.inStock && <div className="out-of-stock-overlay">Out of Stock</div>}
      </div>
      <div className="product-details">
        <h3 className="product-name">{product.name}</h3>
        <p className="product-description">{product.description}</p>
        <div className="product-info">
          <span className="product-price">${product.price}</span>
          <span className={`product-stock ${product.inStock ? 'in-stock' : 'out-of-stock'}`}>
            {product.inStock ? `Stock: ${product.stockQuantity}` : 'Out of Stock'}
          </span>
        </div>
        <div className="product-actions">
          <div className="quantity-selector">
            <button
              onClick={() => setQuantity(Math.max(1, quantity - 1))}
              disabled={!product.inStock || loading}
              className="quantity-btn"
            >
              -
            </button>
            <input
              type="number"
              value={quantity}
              onChange={(e) => setQuantity(Math.max(1, Math.min(product.stockQuantity, parseInt(e.target.value) || 1)))}
              disabled={!product.inStock || loading}
              className="quantity-input"
              min="1"
              max={product.stockQuantity}
            />
            <button
              onClick={() => setQuantity(Math.min(product.stockQuantity, quantity + 1))}
              disabled={!product.inStock || loading}
              className="quantity-btn"
            >
              +
            </button>
          </div>
          <button
            onClick={handleBuyClick}
            disabled={!product.inStock || loading}
            className="buy-now-btn"
          >
            {loading ? 'Processing...' : 'Buy Now'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ProductCard;
