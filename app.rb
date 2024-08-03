# frozen_string_literal: true

require 'dotenv/load'
require 'faraday'
require 'pry'

require_relative 'lib/data_model'
require_relative 'lib/graph_generator'
require_relative 'lib/telegram_api'

MONOBANK_API_URL = 'https://api.monobank.ua/bank/currency'
USD = 840
UAH = 980
NBU_LIMIT = 50_000.0

# Fetch rates from Monobank API
def fetch_rates
  return { buy: rand(40.0..41.0).round(4), sell: rand(41.0..42.0).round(4) } if test_run?

  response = Faraday.get(MONOBANK_API_URL)
  data = JSON.parse(response.body)

  raise data['errText'].to_s if data.is_a?(Hash)

  usd_rate = data.find { |rate| rate['currencyCodeA'] == USD && rate['currencyCodeB'] == UAH }
  { buy: usd_rate['rateBuy'], sell: usd_rate['rateSell'] }
end

def historical_rates
  @historical_rates ||= CurrencyRate.order(:created_at)
end

def labels
  @labels ||= historical_rates
              .pluck('DATE(created_at)')
              .each_with_index
              .chunk_while { |date1, date2| date1[0] == date2[0] }
              .to_h { |chunk| chunk.first.reverse }
end

def message
  rates = @fetched_rates
  ratio = ((rates.sell / rates.buy) - 1) * 100
  commission = ((rates.sell - rates.buy) * 1000).round(2)

  <<~MESSAGE
    <b><i>#{Time.now}</i></b>
    <b>USD Buy:</b> #{rates.buy}, <b>USD Sell:</b> #{rates.sell}
    <b>Ratio:</b> #{ratio.round(2)}% (₴#{commission})
    <b>50K amount:</b> $#{(NBU_LIMIT / rates.sell).round(2)}
    <b>To sell:</b> $#{(NBU_LIMIT / rates.buy).round(2)}
    <b>Diff:</b> $#{(NBU_LIMIT * ((1.0 / rates.buy) - (1.0 / rates.sell))).round(2)}
  MESSAGE
end

def test_run?
  ENV['TEST_RUN'] == 'yes'
end

def same_rates?
  previous_rates = CurrencyRate.order(:created_at).last

  return false if previous_rates.nil?
  return false if Time.now.hour == 9 && (Time.now.day != previous_rates.created_at.day)

  previous_rates.sell == @fetched_rates.sell && previous_rates.buy == @fetched_rates.buy
end

def log_record(message)
  puts "#### #{Time.now} #{message} ####"
end

IMAGE_SET = [:buy_sell_graph, :ratio_graph, :diff_graph]

def images
  GraphGenerator.new(rates: historical_rates).yield_self do |g|
    IMAGE_SET.map { |name| g.public_send(name) }
  end
end

# Notify and store rates
begin
  @fetched_rates = CurrencyRate.build(fetch_rates)

  if !test_run? && same_rates?
    log_record 'Rates are the same - skipping main logic'
    return
  end

  @fetched_rates.save! unless test_run?
  log_record @fetched_rates.attributes.to_s
  CurrencyRate.perform_housekeeping
  TelegramApi.send_message(images:, message:)
rescue StandardError => e
  log_record "#{e.class} - #{e.message}"
end
