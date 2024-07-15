# frozen_string_literal: true

require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: "#{__dir__}/../development.sqlite3")

# Create table structure for buy and sell rates
class CreateCurrencyRatesTable < ActiveRecord::Migration[7.1]
  def change
    create_table :currency_rates do |table|
      table.float :buy
      table.float :sell
      table.timestamps
    end
  end
end

# Create the table
CreateCurrencyRatesTable.migrate(:up)
