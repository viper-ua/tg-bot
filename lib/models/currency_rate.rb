# frozen_string_literal: true

# CurrencyRate model
class CurrencyRate < ActiveRecord::Base
  COMPARISON_ATTRIBUTES = %i[buy sell].freeze
  MAX_HISTORICAL_RECORDS = 45

  class << self
    def last_known_rate = order(created_at: :desc).take
    def rates_for_today? = exists?(created_at: Date.today.all_day)

    def last_rates(max_records = MAX_HISTORICAL_RECORDS)
      from(order(created_at: :desc).limit(max_records), :currency_rates).order(:created_at)
    end
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    COMPARISON_ATTRIBUTES.all? { |attr| public_send(attr) == other.public_send(attr) }
  end
end
