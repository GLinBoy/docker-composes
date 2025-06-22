FROM alpine:3.22.0

# Metadata labels
LABEL maintainer="your-email@example.com"
LABEL description="Alpine Linux with aria2c RPC enabled"
LABEL version="1.0"

# Define build argument and environment variable for port
ARG ARIA2_PORT=6800
ENV ARIA2_PORT=${ARIA2_PORT}

# Install aria2 and necessary dependencies in a single RUN to reduce layers
# Clean up apk cache to reduce image size
RUN apk add --no-cache aria2 && \
  rm -rf /var/cache/apk/*

# Create non-root user and group for better security
RUN addgroup -S aria2group && adduser -S aria2user -G aria2group

# Create directories and set appropriate permissions
RUN mkdir -p /aria2c/conf /aria2c/downloads && \
  chown -R aria2user:aria2group /aria2c && \
  chmod -R 755 /aria2c/downloads

# Expose the configurable port
EXPOSE ${ARIA2_PORT}

# Set working directory
WORKDIR /aria2c

# Copy and secure entrypoint script
COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh && \
  chown aria2user:aria2group entrypoint.sh

# Run as non-root user for better security
USER aria2user

# Healthcheck to verify aria2c is running
# HEALTHCHECK --interval=30s --timeout=3s \
#     CMD wget --no-verbose --tries=1 --spider http://localhost:${ARIA2_PORT}/rpc || exit 1

# Entrypoint to start aria2c with configurable port
ENTRYPOINT ["sh", "entrypoint.sh"]
