# frozen_string_literal: true

require_relative '../apis/mono_api'
require_relative '../apis/telegram_api'
require_relative '../generators/balance_message_generator'

# BalanceCheck workflow to fetch and report account balances
# This class is responsible for fetching the account balances from the MonoBank API
# and sending a notification with the balances.
#
# @example
#   BalanceCheck.run(logger:, test_run:)
#
# @param logger [Logger] The logger instance to log messages.
# @param test_run [Boolean] Indicates if this is a test run.
#
# @return [void]
class BalanceCheck
  REPORTING_HOUR = 9

  class << self
    def run(logger:, test_run:)
      @balances = MonoApi.fetch_balances(test_run:)
      logger.info({ balances:, test_run: })
      return if !test_run && !time_to_report?

      TelegramApi.send_message(message:)
    rescue StandardError => e
      logger.error("#{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
    end

    attr_reader :balances

    private

    def message = BalanceMessageGenerator.message(balances:)
    def time_to_report? = Time.now.hour >= REPORTING_HOUR
  end
end
