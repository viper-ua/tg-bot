# frozen_string_literal: true

require 'dotenv/load'
require 'rufus-scheduler'

require_relative 'lib/workflows/usd_rates_update'

def test_run = ENV['TEST_RUN'] == 'yes'

def logger
  return @logger if defined?(@logger)

  @logger = Logger.new('app.log', 'daily')
end

# Notify and store rates every 5 minutes
Rufus::Scheduler.new.tap do |scheduler|
  scheduler.cron '*/5 * * * *' do
    UsdRatesUpdate.new(logger:, test_run:).run
  end

  scheduler.join # Keep the scheduler running
end
