# Base image for arm64v8
FROM ruby:3.4-slim AS base

# Installing all packets we need including cron
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libmagickwand-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base AS dependencies

# Set workdir for gem installation
WORKDIR /app

# Copying Gemfile and Gemfile.lock, gems installation
COPY Gemfile Gemfile.lock ./
RUN bundle config set without "development test" && \
    bundle install --jobs=3 --retry=3 --no-cache

FROM base

# Set workdir
WORKDIR /app

# Adding user to run the application
RUN adduser --system --group app && chown -R app:app /app
USER app


# Copying gems from the dependencies stage
COPY --from=dependencies /usr/local/bundle /usr/local/bundle

# Copying application code
COPY . .

# Create ./tmp directory and logs
RUN mkdir -p ./tmp && \
    touch /app/app.log && \
    chmod 644 /app/app.log

# Command to execute when container starts
CMD ["/app/run.sh"]