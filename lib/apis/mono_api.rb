# frozen_string_literal: true

require 'faraday'

# MonoBank API to fetch currency rates and account information
class MonoApi
  API_URLS = {
    currency: 'https://api.monobank.ua/bank/currency',
    client_info: 'https://api.monobank.ua/personal/client-info'
  }.freeze

  CURRENCY_CODES = {
    usd: 840,
    uah: 980
  }.freeze

  class << self
    # Fetch rates from Monobank API
    def fetch_rates(test_run: false)
      return random_rates if test_run

      response = Faraday.get(API_URLS[:currency])
      data = JSON.parse(response.body)

      raise data['errText'].to_s if data.is_a?(Hash)

      usd_rate = data.find do |rate|
        rate['currencyCodeA'] == CURRENCY_CODES[:usd] &&
          rate['currencyCodeB'] == CURRENCY_CODES[:uah]
      end

      { buy: usd_rate['rateBuy'], sell: usd_rate['rateSell'] }
    end

    # Fetch account balances from Monobank API
    def fetch_balances(test_run: false)
      return random_balances if test_run

      response = Faraday.get(API_URLS[:client_info]) do |req|
        req.headers['X-Token'] = ENV.fetch('MONO_API_TOKEN')
      end
      data = JSON.parse(response.body)

      raise data['errText'].to_s if data.is_a?(Hash)

      data['accounts']
    end

    private

    def random_rates
      { buy: rand(40.0..41.0).round(4), sell: rand(41.0..42.0).round(4) }
    end

    def random_balances
      [
        {
          'title' => 'Main Account',
          'balance' => rand(100_000..1_000_000),
          'creditLimit' => 0
        },
        {
          'title' => 'Credit Card',
          'balance' => rand(-50_000..50_000),
          'creditLimit' => 100_000
        }
      ]
    end
  end
end
