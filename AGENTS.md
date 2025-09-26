# Agent Instructions for Ruby on Rails Order App

## Project Structure
This is a Rails 7.1 API with GraphQL. Main code is in `order_backend/` directory.

## Commands
- Test: `bin/rails test` (all tests), `bin/rails test test/path/to/specific_test.rb` (single test)  
- Lint: `bin/rubocop` (check), `bin/rubocop -a` (auto-fix)
- Security: `bin/brakeman` (vulnerability scan)
- Database: `bin/rails db:migrate`, `bin/rails db:test:prepare`
- Server: `bin/rails server` or `bin/dev`

## Code Style
- Uses `rubocop-rails-omakase` for styling (see `.rubocop.yml`)
- Add `# frozen_string_literal: true` to top of all Ruby files
- Use double quotes for strings consistently
- Snake_case for variables/methods, PascalCase for classes/modules
- Place GraphQL types in `app/graphql/types/` with proper inheritance
- Controllers inherit from `ApplicationController < ActionController::API`
- Models inherit from `ApplicationRecord < ActiveRecord::Base`

## Error Handling
- Use Rails standard exception handling patterns
- GraphQL errors should be handled in resolvers/mutations appropriately