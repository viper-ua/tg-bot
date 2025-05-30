# frozen_string_literal: true

module Workflows
  # UsdRatesUpdate workflow to fetch, save and report USD rates
  # This class is responsible for fetching the USD rates from the MonoBank API,
  # saving them to the database, and sending a notification with the rates.
  # It also generates graphs for visual representation of the rates.
  #
  # @example
  #   Workflows::UsdRatesUpdate.run(logger:, test_run:)
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
        @fetched_rates = CurrencyRate.build(mono_client(test_run:).fetch_rates)
        logger.info({ **fetched_rates.attributes.compact, test_run: })
        return if !test_run && !time_to_report? && same_rates?

        fetched_rates.save! unless test_run
        Apis::TelegramApi.send_media_message(images:, message:)
      rescue StandardError => e
        logger.error("#{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
      end

      attr_reader :fetched_rates

      private

      def images
        Generators::GraphGenerator
          .new(rates: CurrencyRate.last_rates)
          .then { |g| IMAGE_SET.map { |name| g.public_send(name) } }
      end

      def mono_client(...) = Apis::MonoApi.new(...)
      def message = Generators::MessageGenerator.message(rates: fetched_rates)
      def time_to_report? = (Time.now.hour >= REPORTING_HOUR) && !CurrencyRate.rates_for_today?

      def same_rates?
        previous_rates = CurrencyRate.last_known_rate
        return false if previous_rates.nil?

        previous_rates == fetched_rates
      end
    end
  end
end
