# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CurrencyRate do
  describe '.last_known_rate' do
    it 'returns latest created rate from db' do
      create(:currency_rate, created_at: 3.days.ago)
      create(:currency_rate, created_at: 2.days.ago)
      newest_rate = create(:currency_rate, created_at: 1.day.ago)

      expect(described_class.last_known_rate).to eq(newest_rate)
    end

    it 'returns nil if no records yet' do
      expect(described_class.last_known_rate).to be_nil
    end
  end

  describe '.rates_for_today?' do
    context 'when there are records created today' do
      it 'returns true' do
        create(:currency_rate, created_at: Time.now)

        expect(described_class.rates_for_today?).to be true
      end
    end

    context 'when last record is not from today' do
      it 'returns false' do
        create(:currency_rate, created_at: 1.day.ago)

        expect(described_class.rates_for_today?).to be false
      end
    end
  end

  describe '.last_rates' do
    before do
      test_records_count = described_class::MAX_HISTORICAL_RECORDS + 1
      test_records_count.times do |i|
        create(:currency_rate, created_at: (test_records_count - i).days.ago)
      end
    end

    it 'returns records ordered by date' do
      rates = described_class.last_rates
      expect(rates.first.created_at).to be < rates.last.created_at
    end

    it 'limits number of returned records to MAX_HISTORICAL_RECORDS by default' do
      expect(described_class.last_rates.count).to eq(described_class::MAX_HISTORICAL_RECORDS)
    end

    it 'allows providing own limit of records to return' do
      custom_limit = 10
      expect(described_class.last_rates(custom_limit).count).to eq(custom_limit)
    end
  end

  describe '#==' do
    let(:rate) { create(:currency_rate, buy: 40.5, sell: 41.0) }

    it 'returns true for the same buy and sell values' do
      other_rate = create(:currency_rate, buy: 40.5, sell: 41.0, created_at: 1.day.ago)
      expect(rate == other_rate).to be true
    end

    it 'returns false for different value of buy' do
      other_rate = create(:currency_rate, buy: 40.8, sell: 41.0)
      expect(rate == other_rate).to be false
    end

    it 'returns false for different value of sell' do
      other_rate = create(:currency_rate, buy: 40.5, sell: 41.3)
      expect(rate == other_rate).to be false
    end

    it 'returns false when compared to different object' do
      expect(rate == 'not a currency rate').to be false
    end
  end
end
