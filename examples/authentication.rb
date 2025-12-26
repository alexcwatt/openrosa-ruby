# frozen_string_literal: true

# Authentication examples for OpenRosa middleware

require "open_rosa"

# rubocop:disable Metrics/MethodLength

# Example 1: HTTP Basic Authentication (most common for ODK clients)
class BasicAuthExample
  def self.middleware
    OpenRosa::Middleware.new do |config|
      config.forms = [] # Add your forms here

      config.authenticate do |env|
        auth = Rack::Auth::Basic::Request.new(env)
        if auth.provided? && auth.basic? && auth.credentials
          username, password = auth.credentials
          # Replace with your authentication logic:
          # User.find_by(username: username)&.authenticate(password)
          { username: username } if username == "admin" && password == "secret"
        end
      end

      # Optional: Customize the realm shown in browser login prompt
      config.authentication_realm = "ODK Collect"
    end
  end
end

# Example 2: Bearer Token Authentication (e.g. for API clients)
class TokenAuthExample
  def self.middleware
    OpenRosa::Middleware.new do |config|
      config.forms = [] # Add your forms here

      config.authenticate do |env|
        token = env["HTTP_AUTHORIZATION"]&.sub(/^Bearer /, "")
        # Replace with your token validation:
        # ApiKey.find_by(token: token, active: true)&.user
        { token: token } if token == "valid-token-12345"
      end
    end
  end
end

# Example 3: Selective Authentication (public formList, protected submissions)
class SelectiveAuthExample
  def self.middleware
    OpenRosa::Middleware.new do |config|
      config.forms = [] # Add your forms here

      config.authenticate do |env|
        auth = Rack::Auth::Basic::Request.new(env)
        if auth.provided? && auth.basic? && auth.credentials
          username, password = auth.credentials
          username == "admin" && password == "secret"
        end
      end

      # Skip auth for these paths (supports strings and regex)
      config.skip_authentication_for = ["/formList", %r{/forms/}]
    end
  end
end

# Usage in config.ru:
#   require_relative "examples/authentication"
#   run BasicAuthExample.middleware
#
# In Rails (config/application.rb):
#   config.middleware.use OpenRosa::Middleware do |config|
#     config.authenticate do |env|
#       # Your auth logic here
#     end
#   end
#
# The authenticated user is stored in env["openrosa.authenticated_user"]

# rubocop:enable Metrics/MethodLength
