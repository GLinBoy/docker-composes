# Stage 1: Build AriaNG
FROM node:18-alpine AS builder

LABEL maintainer="your-email@example.com"
LABEL description="Build stage for AriaNG web UI."

WORKDIR /app

# Install git for cloning the repository and gulp for building
RUN apk add --no-cache git && \
  npm install -g gulp

# Argument to specify AriaNG version (optional, defaults to cloning master/main)
# You can find releases at https://github.com/mayswind/AriaNg/releases
ARG ARIANG_VERSION
# Example: docker build --build-arg ARIANG_VERSION=v1.3.7 -t ariang .

# Clone AriaNG repository
# If ARIANG_VERSION is set, clone that specific tag. Otherwise, clone the latest from master.
RUN if [ -z "$ARIANG_VERSION" ]; then \
  echo "Cloning latest AriaNG from master branch..."; \
  git clone --depth 1 https://github.com/mayswind/AriaNg.git .; \
  else \
  echo "Cloning AriaNG version: $ARIANG_VERSION"; \
  git clone --depth 1 --branch ${ARIANG_VERSION} https://github.com/mayswind/AriaNg.git .; \
  fi

# Install AriaNG dependencies
RUN npm install

# Build AriaNG
# The 'gulp clean build' command cleans previous builds and creates a new one in the 'dist' directory.
RUN gulp clean build

# Stage 2: Serve AriaNG with Nginx
FROM nginx:1.27-alpine-slim AS production

LABEL maintainer="your-email@example.com"
LABEL description="AriaNG web UI served with Nginx."

# Copy the built static files from the builder stage to the Nginx web root directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Optional: If you have a custom Nginx configuration file (e.g., nginx.conf)
# you can copy it into the image. For AriaNG, the default usually works fine
# as it uses hash-based routing.
# COPY custom-nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for HTTP
EXPOSE 80

# Healthcheck (optional, but good practice)
# Checks if Nginx is serving the index.html page
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
#     CMD curl -f http://localhost/ || exit 1

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
