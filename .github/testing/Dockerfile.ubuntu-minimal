# Ubuntu Minimal Test Environment
# Used for testing AIDA framework dependency validation
# This image intentionally omits some dependencies to test error handling

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install ONLY bash and coreutils (missing git, rsync)
# This will trigger dependency validation errors in install.sh
RUN apt-get update && apt-get install -y \
    bash \
    coreutils \
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

# Note: This environment is missing:
# - git
# - rsync
# This should cause install.sh to fail with helpful error messages

CMD ["/bin/bash"]
