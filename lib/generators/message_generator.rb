# frozen_string_literal: true

require_relative '../calculation_helpers'

# Class responsible for message generation, with rates and some indicators
class MessageGenerator
  include CalculationHelpers

  def initialize(rates:)
    @rates = rates
  end

  attr_reader :rates

  def message
    <<~MESSAGE
      <b><i>#{Time.now}</i></b>
      <b>USD Buy:</b> #{rates.buy}, <b>USD Sell:</b> #{rates.sell}
      <b>Ratio:</b> #{ratio(rates)}% (₴#{commission(rates)})
      <b>50K amount:</b> $#{max_to_buy(rates)}
      <b>To sell:</b> $#{sell_to_limit(rates)}
      <b>Diff:</b> $#{conversion_diff(rates)}
    MESSAGE
  end
end
