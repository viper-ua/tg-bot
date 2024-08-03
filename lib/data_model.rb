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

  scope :historical_rates, -> { order(:created_at) }

  class << self
    # Keep only last MAX_RECORDS
    def perform_housekeeping
      rate_ids_to_keep = select(:id).order(created_at: :desc).limit(MAX_RECORDS)
      where.not(id: rate_ids_to_keep).destroy_all
    end

    def last_known_rate
      historical_rates.last
    end
  end
end
