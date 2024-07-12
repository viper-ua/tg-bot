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

  raise RuntimeError.new(data['errText']) if data.is_a?(Hash)

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
  CurrencyRate.create(buy: buy, sell: sell)
  CurrencyRate.order(:created_at).first.destroy if CurrencyRate.count > 10
end

# Generate graph of last 10 rates
def generate_buy_sell_graph
  g = Gruff::Line.new
  g.title = 'USD Buy/Sell Rates'

  rates = CurrencyRate.order(:created_at).last(10)
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

  rates = CurrencyRate.order(:created_at).last(10)
  labels = rates.each_with_index.map { |rate, index| [index, rate.created_at.strftime('%d-%m-%y %H:%M')] }.to_h

  g.data(:Ratio, rates.map {|rate| (rate.sell/rate.buy).round(4)})
  g.labels = labels
  g.label_rotation = 45.0
  g.maximum_value = 1.015
  g.minimum_value = 1.005

  image_path = 'ratios.png'
  g.write(image_path)
  image_path
end

def message(rates)
  ratio = rates[:sell] / rates[:buy]
  message = <<~MESSAGE
  #{Time.now}
  USD Buy: #{rates[:buy]}, USD Sell: #{rates[:sell]}
  Ratio: #{ratio.round(4)}
  MESSAGE
end

# Notify and store rates
rates = fetch_rates
store_rate(rates[:buy], rates[:sell])
image_path = generate_buy_sell_graph
send_to_telegram(message(rates), image_path)
image_path = generate_ratio_graph
send_to_telegram(message(rates), image_path)
