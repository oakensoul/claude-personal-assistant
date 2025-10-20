# Debian 12 (Bookworm) Test Environment
# Used for testing AIDA framework installation on Debian 12

FROM debian:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    rsync \
    jq \
    coreutils \
    findutils \
    && rm -rf /var/lib/apt/lists/*

# Verify bash version
RUN bash --version

# Create a test user (non-root)
RUN useradd -m -s /bin/bash testuser

# Set working directory
WORKDIR /workspace

# Switch to test user for installation testing
USER testuser

# Set home directory
ENV HOME=/home/testuser

CMD ["/bin/bash"]
