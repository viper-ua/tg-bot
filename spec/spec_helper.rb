# frozen_string_literal: true

require 'database_cleaner/active_record'
require 'dotenv'
require 'factory_bot'
require 'vcr'
require 'webmock/rspec'
require 'timecop'

Dotenv.load('.env.test')

require_relative '../lib/initializers/db'
require_relative '../lib/initializers/zeitwerk'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!

  # Filter sensitive data
  c.filter_sensitive_data('<TELEGRAM_TOKEN>') { ENV.fetch('TELEGRAM_TOKEN', nil) }
  c.filter_sensitive_data('<TELEGRAM_CHAT_ID>') { ENV.fetch('TELEGRAM_CHAT_ID', nil) }
  c.filter_sensitive_data('<MONO_API_TOKEN>') { ENV.fetch('MONO_API_TOKEN', nil) }
end
