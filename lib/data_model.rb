# frozen_string_literal: true

require 'active_record'

# Database configuration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: "#{__dir__}/../db/development.sqlite3"
)

# CurrencyRate model
class CurrencyRate < ActiveRecord::Base
  MAX_RECORDS = 30

  # Keep only last MAX_RECORDS
  def self.perform_housekeeping
    rate_ids_to_keep = CurrencyRate.select(:id).order(created_at: :desc).limit(MAX_RECORDS)
    CurrencyRate.where.not(id: rate_ids_to_keep).destroy_all
  end
end
