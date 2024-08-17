# frozen_string_literal: true

# Various calculations for rates analysis
module CalculationHelpers
  NBU_LIMIT = 50_000.0

  def ratio(rates) = (((rates.sell / rates.buy) - 1) * 100).round(2)
  def commission(rates) = ((rates.sell - rates.buy) * 1000).round(2)
  def max_to_buy(rates) = (NBU_LIMIT / rates.sell).round(2)
  def sell_to_limit(rates) = (NBU_LIMIT / rates.buy).round(2)
  def conversion_diff(rates) = (NBU_LIMIT * ((1.0 / rates.buy) - (1.0 / rates.sell))).round(2)

  def min_diff_id(rates) = rates.min_by { |rate| rate.sell - rate.buy }.id
  def min_rate_in_increments(rates, increment) = (rates.min_by(&:buy).buy / increment).floor * increment
end
