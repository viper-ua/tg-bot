# frozen_string_literal: true

# MonoBank API to fetch currency rates
class MonoApi
  MONOBANK_API_URL = 'https://api.monobank.ua/bank/currency'
  USD = 840
  UAH = 980

  class << self
    # Fetch rates from Monobank API
    def fetch_rates(test_run: false)
      return random_rates if test_run

      response = Faraday.get(MONOBANK_API_URL)
      data = JSON.parse(response.body)

      raise data['errText'].to_s if data.is_a?(Hash)

      usd_rate = data.find { |rate| rate['currencyCodeA'] == USD && rate['currencyCodeB'] == UAH }
      { buy: usd_rate['rateBuy'], sell: usd_rate['rateSell'] }
    end

    private

    def random_rates
      { buy: rand(40.0..41.0).round(4), sell: rand(41.0..42.0).round(4) }
    end
  end
end
