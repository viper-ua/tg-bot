# frozen_string_literal: true

module Apis
  # Base error class for all MonoBank API related errors
  class MonoApiError < StandardError
    attr_reader :response

    def initialize(message = nil, response = nil)
      @response = response
      super(message)
    end
  end

  # Raised when the API request fails due to authentication issues
  class MonoApiAuthenticationError < MonoApiError; end

  # Raised when the API request fails due to rate limiting
  class MonoApiRateLimitError < MonoApiError; end

  # Raised when the API request fails due to invalid parameters
  class MonoApiValidationError < MonoApiError; end

  # Raised when the API request fails due to server errors
  class MonoApiServerError < MonoApiError; end
end
