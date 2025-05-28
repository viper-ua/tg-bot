# frozen_string_literal: true

require 'dotenv/load' if ENV['APP_ENV'] != 'production'
require 'rufus-scheduler'

require_relative 'lib/initializers/db'
require_relative 'lib/workflows/usd_rates_update'
require_relative 'lib/workflows/balance_check'

def test_run = ENV['TEST_RUN'] == 'yes'

def logger
  return @logger if defined?(@logger)

  @logger = Logger.new('app.log', 'daily')
end

# Notify and store rates every 5 minutes
Rufus::Scheduler.new.tap do |scheduler|
  scheduler.cron '*/2 * * * *' do
    UsdRatesUpdate.run(logger:, test_run:)
  end

  # Check balances every day at 9:00 AM
  scheduler.cron '0 9-20 * * *' do
    BalanceCheck.run(logger:, test_run:)
  end

  scheduler.join # Keep the scheduler running
end
