# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t outcome_tracker_api .
# docker run -d -p 80:3000 -e RAILS_MASTER_KEY=<value from config/master.key> --name outcome_tracker_api outcome_tracker_api

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.4
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client xz-utils imagemagick

# install prebuilt node binary
ARG TARGETARCH
RUN case "$TARGETARCH" in \
    amd64) NODE_ARCH=x64 ;; \
    arm64) NODE_ARCH=arm64 ;; \
    armhf) NODE_ARCH=armv7l ;; \
    *) echo "Unsupported architecture: $TARGETARCH" && exit 1 ;; \
    esac && \
    curl -o node-v22.16.0-linux-${NODE_ARCH}.tar.xz https://nodejs.org/dist/v22.16.0/node-v22.16.0-linux-${NODE_ARCH}.tar.xz && \
    tar -xJf node-v22.16.0-linux-${NODE_ARCH}.tar.xz && \
    mv node-v22.16.0-linux-${NODE_ARCH} /usr/local/node && \
    rm -rf node-v22.16.0-linux-${NODE_ARCH}.tar.xz

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    PATH="/usr/local/node/bin:/usr/local/node/lib/node_modules:$PATH"

RUN --mount=type=cache,target=/root/.npm \
    npm install -g defuddle-cli

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN --mount=type=cache,target=/tmp/bundle-cache \
    cp -r /tmp/bundle-cache/* "${BUNDLE_PATH}/" 2>/dev/null || true && \
    bundle install && \
    cp -r "${BUNDLE_PATH}"/* /tmp/bundle-cache/ && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/




# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
