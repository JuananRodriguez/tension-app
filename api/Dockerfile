FROM rustlang/rust:nightly AS builder

WORKDIR /app

# Copy Cargo files
COPY Cargo.toml Cargo.lock ./

# Create dummy main.rs to cache dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# Copy source code
COPY src ./src

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/target/release/api /usr/local/bin/api

# Expose port
EXPOSE 3000

# Set environment variables
ENV PORT=3000

# Run the application
CMD ["api"]
