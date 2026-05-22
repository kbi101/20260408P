# Multistage build for QuantEdge Frontend
FROM node:20-slim AS builder

WORKDIR /app

# Install dependencies
COPY apps/frontend/package*.json ./
RUN npm install

# Build the app
COPY apps/frontend/ .
ARG VITE_API_BASE_URL
ARG VITE_INFRA_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV VITE_INFRA_BASE_URL=$VITE_INFRA_BASE_URL
RUN npm run build

# Production server
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
# Add custom nginx config
COPY devops/docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
