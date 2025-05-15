# frozen_string_literal: true

require_relative '../apis/mono_api'
require_relative '../apis/telegram_api'
require_relative '../generators/graph_generator'
require_relative '../generators/message_generator'
require_relative '../models/currency_rate'

# UsdRatesUpdate workflow to fetch, save and report USD rates
# This class is responsible for fetching the USD rates from the MonoBank API,
# saving them to the database, and sending a notification with the rates.
# It also generates graphs for visual representation of the rates.
#
# @example
#   UsdRatesUpdate.run(logger:, test_run:)
#
# @param logger [Logger] The logger instance to log messages.
# @param test_run [Boolean] Indicates if this is a test run.
#
# @return [void]
class UsdRatesUpdate
  REPORTING_HOUR = 9
  IMAGE_SET = %i[buy_sell_graph ratio_graph diff_graph].freeze

  class << self
    def run(logger:, test_run:)
      @fetched_rates = CurrencyRate.build(MonoApi.fetch_rates(test_run:))
      logger.info({ **fetched_rates.attributes.compact, test_run: })
      return if !test_run && !time_to_report? && same_rates?

      fetched_rates.save! unless test_run
      TelegramApi.send_message(images:, message:)
    rescue StandardError => e
      logger.error("#{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
    end

    attr_reader :fetched_rates

    private

    def images
      GraphGenerator.new(rates: CurrencyRate.last_rates)
                    .then { |g| IMAGE_SET.map { |name| g.public_send(name) } }
    end

    def message = MessageGenerator.message(rates: fetched_rates)
    def time_to_report? = (Time.now.hour >= REPORTING_HOUR) && CurrencyRate.no_rates_for_today

    def same_rates?
      previous_rates = CurrencyRate.last_known_rate
      return false if previous_rates.nil?

      previous_rates == fetched_rates
    end
  end
end
