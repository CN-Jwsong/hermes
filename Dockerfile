FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HERMES_HOME=/root/.hermes
ENV HERMES_INSTALL_DIR=/root/.hermes/hermes-agent

# Base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ffmpeg \
    ripgrep \
    python3 \
    python3-venv \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Clone Hermes Agent temporarily to install dependencies
RUN git clone https://github.com/NousResearch/hermes-agent.git /tmp/hermes-agent \
    && cd /tmp/hermes-agent \
    && python3 -m venv .venv \
    && /tmp/hermes-agent/.venv/bin/pip install --upgrade pip \
    && /tmp/hermes-agent/.venv/bin/pip install -e . \
    && /tmp/hermes-agent/.venv/bin/pip install fastapi uvicorn \
    && mkdir -p /opt/hermes \
    && cp -r /tmp/hermes-agent/.venv /opt/hermes/ \
    && cp /tmp/hermes-agent/*.toml /tmp/hermes-agent/*.py /opt/hermes/ 2>/dev/null || true \
    && rm -rf /tmp/hermes-agent

WORKDIR /root/.hermes

ENV PATH="/opt/hermes/.venv/bin:$PATH"

# Add hermes to PATH
RUN ln -s /opt/hermes/.venv/bin/hermes /usr/local/bin/hermes

# Initialize shell
RUN echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc

# Default entrypoint
CMD ["hermes"]
