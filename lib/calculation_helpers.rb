# frozen_string_literal: true

# Various calculations for rates analysis
module CalculationHelpers
  NBU_LIMIT = 50_000.0

  def ratio(rate) = (((rate.sell / rate.buy) - 1) * 100).round(2)
  def commission(rate) = ((rate.sell - rate.buy) * 1000).round(2)
  def max_to_buy(rate) = (NBU_LIMIT / rate.sell).round(2)
  def sell_to_limit(rate) = (NBU_LIMIT / rate.buy).round(2)
  def conversion_diff(rate) = (NBU_LIMIT * ((1.0 / rate.buy) - (1.0 / rate.sell))).round(2)

  def min_diff_id(rates)
    return nil unless rates.is_a?(Array) && rates.size > 0

    min_id = nil
    min_val = Float::INFINITY
    rates.reverse_each do |rate|
      next unless rate.sell - rate.buy < min_val

      min_id = rate.id
      min_val = rate.sell - rate.buy
    end
    min_id
  end

  def min_rate_in_increments(rates, increment) = ((rates.min_by(&:buy)&.buy || 0) / increment).floor * increment
end
