# =========================
# Stage 1: Builder
# =========================
FROM python:3.11-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMES_DIR=/opt/hermes

# Install build dependencies (only for compilation)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (required for Hermes gateway/dashboard build steps)
RUN curl -fsSL https://nodejs.org/dist/v22.0.0/node-v22.0.0-linux-x64.tar.gz -o node.tar.gz \
    && tar -xzf node.tar.gz -C /usr/local --strip-components=1 \
    && rm -f node.tar.gz

# Clone Hermes repository
RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git $HERMES_DIR

WORKDIR $HERMES_DIR

# Create virtual environment and install dependencies
RUN python -m venv .venv \
    && .venv/bin/pip install --upgrade pip setuptools wheel \
    # Install main package
    && .venv/bin/pip install --no-cache-dir -e . \
    # Install dashboard dependencies (fix: fastapi missing issue)
    && .venv/bin/pip install --no-cache-dir fastapi uvicorn \
    # Cleanup pip cache
    && rm -rf /root/.cache/pip


# =========================
# Stage 2: Runtime
# =========================
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMES_HOME=/root/.hermes
ENV PATH="/opt/hermes/.venv/bin:/usr/local/bin:$PATH"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    ffmpeg \
    ripgrep \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js runtime (required for gateway/dashboard execution)
RUN curl -fsSL https://nodejs.org/dist/v22.0.0/node-v22.0.0-linux-x64.tar.gz -o node.tar.gz \
    && tar -xzf node.tar.gz -C /usr/local --strip-components=1 \
    && rm -f node.tar.gz

# Copy built Hermes environment
COPY --from=builder /opt/hermes /opt/hermes

# Clean unnecessary files to reduce image size
RUN rm -rf \
    /opt/hermes/.git \
    /root/.cache \
    /tmp/* \
    && find /opt/hermes -name "__pycache__" -exec rm -rf {} + \
    && find /opt/hermes -name "*.pyc" -delete

# Create CLI symlink
RUN ln -s /opt/hermes/.venv/bin/hermes /usr/local/bin/hermes \
    && mkdir -p /root/.hermes

# Set working directory (K8s persistent mount point)
WORKDIR /root/.hermes

# Default command (recommended for K8s deployment)
CMD ["hermes"]
