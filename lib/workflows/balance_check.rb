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
  def self.run(...) = new(...).run

  def initialize(logger:, test_run:)
    @logger = logger
    @test_run = test_run
    @mono_client = Apis::MonoApi.new(api_token: ENV.fetch('MONO_API_TOKEN'), test_run:)
  end

  def run
    @balances = mono_client(test_run:).fetch_balances
    logger.info({ balances:, test_run: })

    TelegramApi.send_message(text:)
  rescue StandardError => e
    logger.error("#{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
  end

  attr_reader :balances, :mono_client, :test_run

  private

  def text = BalanceMessageGenerator.new.message(balances:)
end
