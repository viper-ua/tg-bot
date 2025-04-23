# frozen_string_literal: true

require 'active_record'

# Database configuration

env_name = ENV['APP_ENV'] || 'development'
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: "#{Dir.pwd}/db/#{env_name}.sqlite3"
)

# Create the currency_rates table if it doesn't exist
# Using Active Record migrations is overkill in this simple case
unless ActiveRecord::Base.connection.table_exists?(:currency_rates)
  ActiveRecord::Migration.create_table :currency_rates do |table|
    table.float :buy
    table.float :sell
    table.timestamps
  end
end
