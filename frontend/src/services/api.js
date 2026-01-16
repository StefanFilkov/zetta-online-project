import axios from 'axios';

const INVENTORY_SERVICE_URL = 'http://localhost:8081/api';
const ORDER_SERVICE_URL = 'http://localhost:8082/api';

// Create axios instance with default config
const apiClient = axios.create({
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Inventory Service APIs
export const inventoryService = {
  getAllProducts: async () => {
    try {
      const response = await apiClient.get(`${INVENTORY_SERVICE_URL}/products`);
      return response.data;
    } catch (error) {
      console.error('Error fetching products:', error);
      throw error;
    }
  },

  getProductById: async (id) => {
    try {
      const response = await apiClient.get(`${INVENTORY_SERVICE_URL}/products/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error fetching product ${id}:`, error);
      throw error;
    }
  },
};

// Order Service APIs
export const orderService = {
  createOrder: async (orderData) => {
    try {
      const response = await apiClient.post(`${ORDER_SERVICE_URL}/orders`, orderData);
      return response.data;
    } catch (error) {
      console.error('Error creating order:', error);
      throw error;
    }
  },

  getAllOrders: async () => {
    try {
      const response = await apiClient.get(`${ORDER_SERVICE_URL}/orders`);
      return response.data;
    } catch (error) {
      console.error('Error fetching orders:', error);
      throw error;
    }
  },

  getOrderById: async (id) => {
    try {
      const response = await apiClient.get(`${ORDER_SERVICE_URL}/orders/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error fetching order ${id}:`, error);
      throw error;
    }
  },
};
