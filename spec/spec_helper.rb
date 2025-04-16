# frozen_string_literal: true

require 'factory_bot'
require 'database_cleaner/active_record'
require 'dotenv'
require_relative '../lib/data_model'
require_relative '../lib/calculation_helpers'

Dotenv.load('.env.test')

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
