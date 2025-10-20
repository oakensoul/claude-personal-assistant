# Multi-stage Dockerfile for AIDA upgrade testing
# Supports: fresh install, upgrade scenarios, migration testing, dev mode
# Platforms: Ubuntu 22.04 LTS (primary), 24.04 LTS (future)

# Build argument for Ubuntu version
ARG UBUNTU_VERSION=22.04

# =============================================================================
# Stage 1: Base environment
# =============================================================================
FROM ubuntu:${UBUNTU_VERSION} AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    jq \
    tree \
    file \
    ca-certificates \
    gnupg \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install shellcheck from snap (preferred) or fallback to apt
RUN apt-get update && apt-get install -y shellcheck \
    || (apt-get install -y snapd && snap install shellcheck) \
    && rm -rf /var/lib/apt/lists/*

# Create test user (non-root) for realistic testing
RUN useradd -m -s /bin/bash testuser && \
    mkdir -p /home/testuser

# =============================================================================
# Stage 2: Test environment with AIDA dependencies
# =============================================================================
FROM base AS test-env

# Install bats testing framework
WORKDIR /tmp
RUN git clone --depth 1 --branch v1.10.0 https://github.com/bats-core/bats-core.git && \
    cd bats-core && \
    ./install.sh /usr/local && \
    cd .. && \
    rm -rf bats-core

# Install bats-support library
RUN git clone --depth 1 https://github.com/bats-core/bats-support.git /usr/local/lib/bats-support

# Install bats-assert library
RUN git clone --depth 1 https://github.com/bats-core/bats-assert.git /usr/local/lib/bats-assert

# Verify installations
RUN bats --version && \
    shellcheck --version && \
    jq --version

# =============================================================================
# Stage 3: Upgrade testing environment
# =============================================================================
FROM test-env AS upgrade-test

# Environment variables for AIDA installation
ENV AIDA_HOME=/home/testuser/.aida
ENV CLAUDE_CONFIG_DIR=/home/testuser/.claude
ENV HOME=/home/testuser

# Test configuration environment variables
ENV INSTALL_MODE=normal
ENV WITH_DEPRECATED=false
ENV TEST_SCENARIO=fresh
ENV DEBUG=false
ENV VERBOSE=false

# Create volume mount points
RUN mkdir -p /workspace \
    /test-fixtures \
    /test-results \
    && chown -R testuser:testuser /workspace /test-fixtures /test-results

# Create AIDA directories with correct ownership
RUN mkdir -p ${AIDA_HOME} ${CLAUDE_CONFIG_DIR} \
    && chown -R testuser:testuser ${AIDA_HOME} ${CLAUDE_CONFIG_DIR}

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch to test user
USER testuser
WORKDIR ${HOME}

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command: run all tests
CMD ["test-all"]

# =============================================================================
# Build metadata
# =============================================================================
LABEL maintainer="AIDA Framework"
LABEL description="Docker environment for AIDA upgrade testing"
LABEL version="0.2.0"
LABEL ubuntu.version="${UBUNTU_VERSION}"

# Build-time metadata
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.source="https://github.com/oakensoul/claude-personal-assistant"
