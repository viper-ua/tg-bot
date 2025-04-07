# Base image for arm64v8
FROM ruby:3.4-slim AS base

# Installing all packets we need including cron
RUN apt-get update && apt-get install -y \
    build-essential \
    libmagickwand-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base AS dependencies

# Copying Gemfile and Gemfile.lock, gems installation
COPY Gemfile Gemfile.lock ./
RUN bundle config set without "development test" && \
    bundle install --jobs=3 --retry=3 --no-cache

FROM base

# Adding user to run the application
RUN adduser app
USER app

# Set workdir
WORKDIR /app

# Copying gems from the dependencies stage
COPY --from=dependencies /usr/local/bundle /usr/local/bundle

# Copying application code
COPY . .

# Running an app
CMD ["ruby", "app.rb"]