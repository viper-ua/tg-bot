# frozen_string_literal: true

require 'dotenv/load'
require 'faraday'
require 'pry'

require_relative 'lib/data_model'
require_relative 'lib/graph_generator'
require_relative 'lib/message_generator'
require_relative 'lib/mono_api'
require_relative 'lib/telegram_api'

IMAGE_SET = %i[buy_sell_graph ratio_graph diff_graph].freeze

def images
  GraphGenerator.new(rates: CurrencyRate.historical_rates).then do |g|
    IMAGE_SET.map { |name| g.public_send(name) }
  end
end

def message = MessageGenerator.new(rates: @fetched_rates).message
def test_run? = ENV['TEST_RUN'] == 'yes'

def same_rates?
  previous_rates = CurrencyRate.last_known_rate

  return false if previous_rates.nil?
  return false if Time.now.hour == 9 && (Time.now.day != previous_rates.created_at.day)

  previous_rates.sell == @fetched_rates.sell && previous_rates.buy == @fetched_rates.buy
end

# Notify and store rates
begin
  logger = Logger.new($stdout)
  @fetched_rates = CurrencyRate.build(MonoApi.fetch_rates(test_run: test_run?))
  return if !test_run? && same_rates?

  @fetched_rates.save! unless test_run?
  logger.info(@fetched_rates.attributes.to_s)
  CurrencyRate.perform_housekeeping
  TelegramApi.send_message(images:, message:)
rescue StandardError => e
  logger.error("#{e.class} - #{e.message}")
end
