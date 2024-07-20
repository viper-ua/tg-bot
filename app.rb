# frozen_string_literal: true

require 'active_record'
require 'dotenv/load'
require 'faraday'
require 'gruff'
require 'rufus-scheduler'
require 'telegram/bot'
require 'pry'

MONOBANK_API_URL = 'https://api.monobank.ua/bank/currency'
MAX_RECORDS = 30
USD = 840
UAH = 980

# Database configuration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: "#{__dir__}/db/development.sqlite3"
)

# CurrencyRate model
class CurrencyRate < ActiveRecord::Base; end

# Fetch rates from Monobank API
def fetch_rates
  response = Faraday.get(MONOBANK_API_URL)
  data = JSON.parse(response.body)

  raise data['errText'].to_s if data.is_a?(Hash)

  usd_rate = data.find { |rate| rate['currencyCodeA'] == USD && rate['currencyCodeB'] == UAH }
  { buy: usd_rate['rateBuy'], sell: usd_rate['rateSell'] }
end

# Send message and graph to Telegram
def send_to_telegram(message, image_path)
  Telegram::Bot::Client.run(ENV['TELEGRAM_TOKEN']) do |bot|
    # bot.api.send_message(chat_id: ENV['TELEGRAM_CHAT_ID'], text: message)
    bot.api.send_photo(
      chat_id: ENV['TELEGRAM_CHAT_ID'],
      caption: message,
      photo: Faraday::UploadIO.new(image_path, 'image/png')
    )
  end
end

# Store rate in the database and maintain only last 10 records
def store_rate(buy, sell)
  CurrencyRate.create(buy:, sell:)
  CurrencyRate.order(:created_at).first.destroy if CurrencyRate.count > MAX_RECORDS
end

# Generate graph of last 10 rates
def generate_buy_sell_graph
  g = Gruff::Line.new
  g.title = 'USD Buy/Sell Rates'

  rates = CurrencyRate.order(:created_at)
  buy_rates = rates.map(&:buy)
  sell_rates = rates.map(&:sell)
  labels = rates.each_with_index.map { |rate, index| [index, rate.created_at.strftime('%d-%m-%y %H:%M')] }.to_h

  g.data(:Buy, buy_rates)
  g.data(:Sell, sell_rates)
  g.labels = labels
  g.minimum_value = 40.0
  g.label_rotation = 45.0

  image_path = 'rates.png'
  g.write(image_path)
  image_path
end

# Generate graph of last 10 Sell/Buy ratios
def generate_ratio_graph
  g = Gruff::Line.new
  g.title = 'USD Sell/Buy Ratios'

  rates = CurrencyRate.order(:created_at)
  labels = rates.each_with_index.map { |rate, index| [index, rate.created_at.strftime('%d-%m-%y %H:%M')] }.to_h

  g.data(:Ratio, rates.map { |rate| (rate.sell / rate.buy).round(4) })
  g.labels = labels
  g.label_rotation = 45.0
  g.maximum_value = 1.015
  g.minimum_value = 1.005

  image_path = 'ratios.png'
  g.write(image_path)
  image_path
end

def message(rates)
  ratio = (rates[:sell] / rates[:buy] - 1).round(4) * 100
  commission = ((rates[:sell] - rates[:buy]) * 1000).round(2)
  

  <<~MESSAGE
    #{Time.now}
    USD Buy: #{rates[:buy]}, USD Sell: #{rates[:sell]}
    Ratio: #{ratio} (₴#{commission})
  MESSAGE
end

def rates_differ?(rates)
  previous_rates = CurrencyRate.order(:created_at).last

  return true if previous_rates.nil?
  return true if Time.now > previous_rates.created_at + 1.day

  previous_rates.sell != rates[:sell] && previous_rates.buy != rates[:buy]
end

def log_record(message)
  puts "#### #{Time.now} #{message} ####"
end

# Notify and store rates
begin
  rates = fetch_rates
  if rates_differ?(rates)
    log_record rates
    store_rate(rates[:buy], rates[:sell])
    image_path = generate_buy_sell_graph
    send_to_telegram(message(rates), image_path)
    image_path = generate_ratio_graph
    send_to_telegram(message(rates), image_path)
  else
    log_record 'Rates are the same - skipping main logic'
  end
rescue StandardError => e
  log_record "#{e.class} - #{e.message}"
end
