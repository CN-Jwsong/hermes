# =========================
# Stage 1: Builder
# =========================
FROM python:3.11-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMES_DIR=/opt/hermes

# Build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Node.js (multi-arch aware)
ARG NODE_VERSION=22.22.0
ARG TARGETARCH
RUN case "$TARGETARCH" in \
        amd64) NODE_ARCH=x64 ;; \
        arm64) NODE_ARCH=arm64 ;; \
        *) echo "Unsupported architecture: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" -o node.tar.gz \
    && tar -xzf node.tar.gz -C /usr/local --strip-components=1 \
    && rm -f node.tar.gz \
    && node --version
# Clone Hermes
RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git $HERMES_DIR

WORKDIR $HERMES_DIR

# Create venv and install dependencies
RUN python -m venv .venv \
    && .venv/bin/pip install --upgrade pip setuptools wheel \
    && .venv/bin/pip install --no-cache-dir -e . \
    && .venv/bin/pip install --no-cache-dir \
        fastapi \
        "uvicorn[standard]" \
        aiohttp \
        cryptography \
    && find .venv -type d -name "__pycache__" -exec rm -rf {} + \
    && rm -rf /root/.cache/pip

# Pre-build web UI so runtime does not need npm install
RUN npm install --no-audit --no-fund \
    && npm run build --workspace web \
    && rm -rf /root/.npm

# =========================
# Stage 2: Runtime
# =========================
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMES_HOME=/root/.hermes
ENV PATH="/opt/hermes/.venv/bin:/usr/local/bin:$PATH"

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    ripgrep \
    ca-certificates \
    git \
    curl \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Node.js runtime (multi-arch aware)
ARG NODE_VERSION=22.22.0
ARG TARGETARCH
RUN case "$TARGETARCH" in \
        amd64) NODE_ARCH=x64 ;; \
        arm64) NODE_ARCH=arm64 ;; \
        *) echo "Unsupported architecture: $TARGETARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" -o node.tar.gz \
    && tar -xzf node.tar.gz -C /usr/local --strip-components=1 \
    && rm -f node.tar.gz \
    && node --version

# Copy built environment
COPY --from=builder /opt/hermes /opt/hermes

# Cleanup
RUN rm -rf \
    /opt/hermes/.git \
    /root/.cache \
    /tmp/* \
    && find /opt/hermes -type d -name "__pycache__" -exec rm -rf {} + \
    && find /opt/hermes -name "*.pyc" -delete

# CLI
RUN ln -s /opt/hermes/.venv/bin/hermes /usr/local/bin/hermes \
    && mkdir -p /root/.hermes

# Timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

WORKDIR /root/.hermes

CMD ["hermes"]
