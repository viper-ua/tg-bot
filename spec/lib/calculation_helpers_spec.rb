# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CalculationHelpers do
  let(:test_class) do
    Class.new do
      include CalculationHelpers
    end
  end

  let(:helper) { test_class.new }
  let(:rate) { create(:currency_rate, buy: 41.0, sell: 41.5) }
  let(:rates) do
    [
      create(:currency_rate, buy: 40.5, sell: 41.0, id: 1),
      create(:currency_rate, buy: 40.6, sell: 40.9, id: 2),
      create(:currency_rate, buy: 40.7, sell: 41.5, id: 3)
    ]
  end

  describe '#ratio' do
    it 'calculates percentage ratio between buy and sell rates' do
      expect(helper.ratio(rate)).to eq(1.22)
    end
  end

  describe '#commission' do
    it 'calculates commission for 1000 units of currency' do
      expect(helper.commission(rate)).to eq(500.0)
    end
  end

  describe '#max_to_buy' do
    it 'calculates maximum amount of currency that can be bought within NBU limit' do
      expect(helper.max_to_buy(rate)).to eq(1204.82)
    end
  end

  describe '#sell_to_limit' do
    it 'calculates amount of currency that can be sold to get the NBU limit' do
      expect(helper.sell_to_limit(rate)).to eq(1219.51)
    end
  end

  describe '#conversion_diff' do
    it 'calculates difference when converting within NBU limit' do
      expect(helper.conversion_diff(rate)).to eq(14.69)
    end
  end

  describe '#min_diff_id' do
    it 'finds ID of the rate with minimum difference between buy and sell' do
      expect(helper.min_diff_id(rates)).to eq(2)
    end
  end

  describe '#min_rate_in_increments' do
    it 'finds minimum buy rate floored to the specified increment', :aggregate_failures do
      # Minimum buy rate: 40.5
      expect(helper.min_rate_in_increments(rates, 0.5)).to eq(40.5)
      expect(helper.min_rate_in_increments(rates, 1.0)).to eq(40.0)
      expect(helper.min_rate_in_increments(rates, 3.0)).to eq(39.0)
    end

    it 'returns 0 if the list is empty' do
      expect(helper.min_rate_in_increments([], 0.5)).to eq(0)
    end
  end
end
