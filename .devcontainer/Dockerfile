# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.4
FROM ruby:$RUBY_VERSION-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    curl \
    git \
    libpq-dev \
    libvips \
    libyaml-dev \
    nodejs \
    npm \
    pkg-config \
    postgresql-client \
    sudo \
    vim \
    wget \
    xz-utils \
    imagemagick \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set the working directory
WORKDIR /workspaces/OutcomeTrackerAPI

# Change ownership of the working directory
RUN chown -R $USERNAME:$USERNAME /workspaces

# Switch to the non-root user
USER $USERNAME

# Install bundler
RUN gem install bundler

# Set environment variables
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    GEM_HOME=/usr/local/bundle
ENV PATH=$BUNDLE_BIN:$PATH

# Default command
CMD ["/bin/bash"]
