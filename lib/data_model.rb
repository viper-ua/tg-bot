# frozen_string_literal: true

require 'active_record'

# Database configuration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: "#{__dir__}/../db/development.sqlite3"
)

# CurrencyRate model
class CurrencyRate < ActiveRecord::Base
  COMPARISON_ATTRIBUTES = %i[buy sell].freeze
  MAX_HISTORICAL_RECORDS = 30

  scope :historical_rates, ->(max_records = MAX_HISTORICAL_RECORDS) { order(:created_at).limit(max_records) }

  class << self
    def last_known_rate
      historical_rates.last
    end

    def no_rates_for_today
      Time.now.day != last_known_rate.created_at.day
    end
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    COMPARISON_ATTRIBUTES.all? { |attr| public_send(attr) == other.public_send(attr) }
  end
end
