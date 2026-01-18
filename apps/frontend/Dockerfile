FROM node:18-alpine AS build

WORKDIR /app

COPY apps/frontend/package*.json ./

RUN npm install

COPY apps/frontend/. .

RUN npm run build

# --- #

FROM nginxinc/nginx-unprivileged:stable-alpine

COPY --from=build /app/build /usr/share/nginx/html

COPY apps/frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
