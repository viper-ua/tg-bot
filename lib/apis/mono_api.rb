# frozen_string_literal: true

require 'faraday'

module Apis
  # MonoBank API client for fetching currency rates and account information
  class MonoApi
    API_URLS = {
      currency: 'https://api.monobank.ua/bank/currency',
      client_info: 'https://api.monobank.ua/personal/client-info'
    }.freeze

    CURRENCY_CODES = {
      usd: 840,
      uah: 980
    }.freeze

    # @param api_token [String] The Monobank API token
    # @param test_run [Boolean] Whether to run in test mode
    def initialize(api_token: nil, test_run: false)
      @api_token = api_token
      @test_run = test_run
      @client = Faraday.new do |conn|
        conn.headers['X-Token'] = @api_token if @api_token
      end
    end

    # Fetch current USD/UAH exchange rates
    # @return [Hash] Hash containing buy and sell rates
    # @raise [MonoApi::Error] If the API request fails
    def fetch_rates
      return random_rates if @test_run

      response = @client.get(API_URLS[:currency])
      data = JSON.parse(response.body)

      raise_if_error(data:, key: 'errText')

      usd_rate = find_usd_rate(data)
      { buy: usd_rate['rateBuy'], sell: usd_rate['rateSell'] }
    end

    # Fetch account balances from Monobank
    # @return [Array<Hash>] Array of account information
    # @raise [MonoApi::Error] If the API request fails
    def fetch_balances
      return random_balances if @test_run

      response = @client.get(API_URLS[:client_info])
      data = JSON.parse(response.body)

      raise_if_error(data:, key: 'errorDescription')

      data['accounts']
    end

    private

    def find_usd_rate(data)
      data.find do |rate|
        rate['currencyCodeA'] == CURRENCY_CODES[:usd] &&
          rate['currencyCodeB'] == CURRENCY_CODES[:uah]
      end
    end

    def random_rates
      { buy: rand(40.0..41.0).round(4), sell: rand(41.0..42.0).round(4) }
    end

    def random_balances
      [
        {
          'type' => 'Main Account',
          'balance' => rand(100_000..1_000_000),
          'creditLimit' => 0
        },
        {
          'type' => 'Credit Card',
          'balance' => rand(-50_000..50_000),
          'creditLimit' => 100_000
        }
      ]
    end

    def raise_if_error(data:, key:)
      return unless data.is_a?(Hash) && data[key]

      error_message = data[key].to_s
      error_class = classify_error(error_message)
      raise error_class.new(error_message, data)
    end

    def classify_error(message)
      case message
      when /token/i
        MonoApi::AuthenticationError
      when /too many requests/i
        MonoApi::RateLimitError
      when /invalid/i
        MonoApi::ValidationError
      else
        MonoApi::ServerError
      end
    end
  end
end
