# frozen_string_literal: true

module Apis
  module MonoApi
    # Base error class for all MonoBank API related errors
    class Error < StandardError
      attr_reader :data

      def initialize(message, data = nil)
        @data = data
        super(message)
      end
    end

    # Raised when the API request fails due to authentication issues
    class AuthenticationError < Error; end

    # Raised when the API request fails due to rate limiting
    class RateLimitError < Error; end

    # Raised when the API request fails due to invalid parameters
    class ValidationError < Error; end

    # Raised when the API request fails due to server errors
    class ServerError < Error; end
  end
end
