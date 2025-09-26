#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Starting build process..."
echo "Ruby version: $(ruby -v)"
echo "Bundler version: $(bundle -v)"

# Set default environment variables if not set
export RAILS_ENV=${RAILS_ENV:-production}
export RAILS_MAX_THREADS=${RAILS_MAX_THREADS:-5}
export JOB_CONCURRENCY=${JOB_CONCURRENCY:-1}

# Install gems
echo "Installing gems..."
bundle install

# Ensure config directory exists and is properly structured
mkdir -p config
mkdir -p tmp/pids

# Verify puma.rb exists and is a file
if [ -f config/puma.rb ]; then
    echo "puma.rb exists as file"
else
    echo "ERROR: puma.rb missing or corrupted"
    ls -la config/
    exit 1
fi

# Precompile assets (skip if no assets)
echo "Precompiling assets..."
if [ -f config/application.rb ]; then
    bundle exec rails assets:precompile || echo "No assets to precompile"
fi

# Database setup
echo "Setting up database..."
bundle exec rails db:create || echo "Database already exists"
bundle exec rails db:migrate
bundle exec rails db:seed || echo "Seeding completed or failed"

echo "Build process completed successfully"