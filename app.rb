# frozen_string_literal: true

require 'active_record'
require 'dotenv/load'
require 'faraday'
require 'telegram/bot'
require 'pry'

require_relative 'lib/graph_generator'

MONOBANK_API_URL = 'https://api.monobank.ua/bank/currency'
USD = 840
UAH = 980
NBU_LIMIT = 50_000.0

# Database configuration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: "#{__dir__}/db/development.sqlite3"
)

# CurrencyRate model
class CurrencyRate < ActiveRecord::Base
  MAX_RECORDS = 20

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
          media: "attach://#{@buy_sell_graph}",
          show_caption_above_media: true
        ),
        Telegram::Bot::Types::InputMediaPhoto.new(
          caption: message,
          media: "attach://#{@ratio_graph}",
          show_caption_above_media: true
        )
      ],
      "#{@buy_sell_graph}": Faraday::UploadIO.new(@buy_sell_graph, 'image/png'),
      "#{@ratio_graph}": Faraday::UploadIO.new(@ratio_graph, 'image/png')
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

def message(rates)
  sell = rates[:sell]
  buy = rates[:buy]
  ratio = (sell / buy - 1) * 100
  commission = ((sell - buy) * 1000).round(2)

  <<~MESSAGE
    #{Time.now}
    USD Buy: #{buy}, USD Sell: #{sell}
    Ratio: #{ratio.round(2)}% (₴#{commission})
    50K amount: $#{(NBU_LIMIT / sell).round(2)}
    To sell: $#{(NBU_LIMIT / buy).round(2)}
    Diff: $#{(NBU_LIMIT * (1.0 / buy - 1.0 / sell)).round(2)}
  MESSAGE
end

def same_rates?(rates)
  return false if ENV['SEND_ANYWAY'] == 'yes'

  previous_rates = CurrencyRate.order(:created_at).last

  return false if previous_rates.nil?
  return false if Time.now > previous_rates.created_at + 1.day

  previous_rates.sell == rates[:sell] && previous_rates.buy == rates[:buy]
end

def log_record(message)
  puts "#### #{Time.now} #{message} ####"
end

def generate_graphs
  generator = GraphGenerator.new(rates:)
  @buy_sell_graph = generator.buy_sell_graph
  @ratio_graph = generator.ratio_graph
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
  generate_graphs
  send_to_telegram(message(current_rates))
rescue StandardError => e
  log_record "#{e.class} - #{e.message}"
end
