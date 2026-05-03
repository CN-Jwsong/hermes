# Stage 1: Builder
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-venv \
    python3-pip \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git /tmp/hermes-agent

RUN cd /tmp/hermes-agent \
    && python3 -m venv /opt/hermes/.venv \
    && /opt/hermes/.venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/hermes/.venv/bin/pip install --no-cache-dir -e /tmp/hermes-agent \
    && /opt/hermes/.venv/bin/pip install --no-cache-dir fastapi uvicorn

# Stage 2: Runtime
FROM ubuntu:24.04-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/hermes/.venv/bin:$PATH"
ENV HERMES_HOME=/root/.hermes

RUN apt-get update && apt-get install -y \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/hermes /opt/hermes

RUN ln -s /opt/hermes/.venv/bin/hermes /usr/local/bin/hermes \
    && mkdir -p /root/.hermes

WORKDIR /root/.hermes

CMD ["hermes"]
