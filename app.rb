# frozen_string_literal: true

require 'dotenv/load'
require 'faraday'
require 'pry'

require_relative 'lib/data_model'
require_relative 'lib/graph_generator'
require_relative 'lib/message_generator'
require_relative 'lib/mono_api'
require_relative 'lib/telegram_api'

REPORTING_HOUR = 9
IMAGE_SET = %i[buy_sell_graph ratio_graph diff_graph].freeze

def images
  GraphGenerator.new(rates: CurrencyRate.last_rates)
                .then { |g| IMAGE_SET.map { |name| g.public_send(name) } }
end

def message = MessageGenerator.new(rates: @fetched_rates).message

def test_run? = ENV['TEST_RUN'] == 'yes'
def time_to_report? = (Time.now.hour == REPORTING_HOUR) && CurrencyRate.no_rates_for_today

def same_rates?
  previous_rates = CurrencyRate.last_known_rate
  return false if previous_rates.nil?

  previous_rates == @fetched_rates
end

# Notify and store rates
begin
  logger = Logger.new($stdout)
  @fetched_rates = CurrencyRate.build(MonoApi.fetch_rates(test_run: test_run?))
  return if !test_run? && !time_to_report? && same_rates?

  @fetched_rates.save! unless test_run?
  logger.info(@fetched_rates.attributes.to_s)
  TelegramApi.send_message(images:, message:)
rescue StandardError => e
  logger.error("#{e.class} - #{e.message}")
end
