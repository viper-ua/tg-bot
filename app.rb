# frozen_string_literal: true

require 'active_record'
require 'dotenv/load'
require 'faraday'
require 'gruff'
require 'rufus-scheduler'
require 'telegram/bot'
require 'pry'

MONOBANK_API_URL = 'https://api.monobank.ua/bank/currency'
USD = 840
UAH = 980

GRAPH_DIMENSIONS = '1280x720'

# Database configuration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: "#{__dir__}/db/development.sqlite3"
)

# CurrencyRate model
class CurrencyRate < ActiveRecord::Base
  MAX_RECORDS = 30

  # Keep only last MAX_RECORDS
  def self.perform_housekeeping
    rate_ids_to_keep = CurrencyRate.select(:id).order(created_at: :desc).limit(MAX_RECORDS)
    CurrencyRate.where.not(id: rate_ids_to_keep).destroy_all
  end
end

# Fetch rates from Monobank API
def fetch_rates
  response = Faraday.get(MONOBANK_API_URL)
  data = JSON.parse(response.body)

  raise data['errText'].to_s if data.is_a?(Hash)

  usd_rate = data.find { |rate| rate['currencyCodeA'] == USD && rate['currencyCodeB'] == UAH }
  { buy: usd_rate['rateBuy'], sell: usd_rate['rateSell'] }
end

# Send message and graphs to Telegram
def send_to_telegram(message)
  Telegram::Bot::Client.run(ENV['TELEGRAM_TOKEN']) do |bot|
    bot.api.send_media_group(
      chat_id: ENV['TELEGRAM_CHAT_ID'],
      media: [
        Telegram::Bot::Types::InputMediaPhoto.new(
          caption: message,
          media: "attach://#{buy_sell_graph}",
          show_caption_above_media: true
        ),
        Telegram::Bot::Types::InputMediaPhoto.new(
      caption: message,
          media: "attach://#{ratio_graph}",
          show_caption_above_media: true
        )
      ],
      "#{buy_sell_graph}": Faraday::UploadIO.new(buy_sell_graph, 'image/png'),
      "#{ratio_graph}": Faraday::UploadIO.new(ratio_graph, 'image/png')
    )
  end
end

def rates
  @rates ||= CurrencyRate.order(:created_at)
end

def labels
  @labels ||= rates.each_with_index
                   .map { |rate, index| [index, rate.created_at.strftime('%d-%m-%y %H:%M ')] }
                   .to_h
end

# Generate graph of last rates
def buy_sell_graph(image_path: 'rates.png')
  return @buy_sell_graph_path if @buy_sell_graph_path
  
  Gruff::Line.new(GRAPH_DIMENSIONS).tap do |graph|
    graph.title = 'USD Buy/Sell Rates'
    graph.data(:Buy, rates.map(&:buy))
    graph.data(:Sell, rates.map(&:sell))
    graph.labels = labels
    graph.minimum_value = rates.map(&:buy).min
    graph.maximum_value = rates.map(&:sell).max
    graph.label_rotation = -45.0
    graph.write(image_path)
  end
  @buy_sell_graph_path = image_path
end

# Generate graph of last Sell/Buy ratios
def ratio_graph(image_path: 'ratios.png')
  return @ratio_graph_path if @ratio_graph_path
  
  data_points = rates.map { |rate| (rate.sell / rate.buy - 1).round(4) * 100 }
  Gruff::Line.new(GRAPH_DIMENSIONS).tap do |graph|
    graph.title = 'USD Sell/Buy Ratios'
    graph.data(:Ratio, data_points)
    graph.labels = labels
    graph.label_rotation = -45.0
    graph.minimum_value = data_points.min
    graph.maximum_value = data_points.max
    graph.write(image_path)
  end
  @ratio_graph_path = image_path
end

def message(rates)
  ratio = (rates[:sell] / rates[:buy] - 1).round(4) * 100
  commission = ((rates[:sell] - rates[:buy]) * 1000).round(2)

  <<~MESSAGE
    #{Time.now}
    USD Buy: #{rates[:buy]}, USD Sell: #{rates[:sell]}
    Ratio: #{ratio}% (₴#{commission})
  MESSAGE
end

def same_rates?(rates)
  previous_rates = CurrencyRate.order(:created_at).last

  return false if previous_rates.nil?
  return false if Time.now > previous_rates.created_at + 1.day

  previous_rates.sell == rates[:sell] && previous_rates.buy == rates[:buy]
end

def log_record(message)
  puts "#### #{Time.now} #{message} ####"
end

# Notify and store rates
begin
  current_rates = fetch_rates

  if same_rates?(current_rates)
    log_record 'Rates are the same - skipping main logic'
    return
  end

  log_record current_rates
  CurrencyRate.create(buy: current_rates[:buy], sell: current_rates[:sell])
  CurrencyRate.perform_housekeeping
  send_to_telegram(message(current_rates))
rescue StandardError => e
  log_record "#{e.class} - #{e.message}"
end
