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

# Clone Hermes Agent
RUN git clone https://github.com/NousResearch/hermes-agent.git $HERMES_INSTALL_DIR

WORKDIR $HERMES_INSTALL_DIR

# Create virtual environment (matches install.sh default behavior)
RUN python3 -m venv .venv
ENV PATH="$HERMES_INSTALL_DIR/.venv/bin:$PATH"

# Install Python dependencies
RUN pip install --upgrade pip \
    && pip install -e .

# Add hermes to PATH
RUN ln -s $HERMES_INSTALL_DIR/.venv/bin/hermes /usr/local/bin/hermes

# Initialize shell
RUN echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc

# Default entrypoint
CMD ["hermes"]
