# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    frontend_urls = [
      "http://localhost:5173",
      "http://localhost:5174",
      "http://127.0.0.1:5173",
      "http://127.0.0.1:5174",
      "http://localhost:3000",
      "https://order-pfmnc96ir-xeins-projects-beed7768.vercel.app",
      "https://order-app-one-eosin.vercel.app"
    ]

    # Add production frontend URL from environment variable if present
    frontend_urls << ENV["FRONTEND_URL"] if ENV["FRONTEND_URL"].present?

    origins frontend_urls.compact

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true
  end
end
