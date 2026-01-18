FROM node:18-alpine AS build

WORKDIR /app

COPY frontend/package*.json ./

RUN npm install

COPY frontend/. .

# Accept build arguments for service URLs
ARG REACT_APP_INVENTORY_SERVICE_URL
ARG REACT_APP_ORDER_SERVICE_URL

# Set them as environment variables for the build
ENV REACT_APP_INVENTORY_SERVICE_URL=$REACT_APP_INVENTORY_SERVICE_URL
ENV REACT_APP_ORDER_SERVICE_URL=$REACT_APP_ORDER_SERVICE_URL

RUN npm run build

# --- #

FROM nginxinc/nginx-unprivileged:stable-alpine

COPY --from=build /app/build /usr/share/nginx/html

COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
