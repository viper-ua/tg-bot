# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MessageGenerator do
  let(:rates) { create(:currency_rate, buy: 40.5, sell: 41.0, id: 1) }

  subject(:message) { described_class.message(rates:) }

  describe '#message' do
    it { is_expected.to include('<b>USD Buy:</b> 40.5, <b>USD Sell:</b> 41.0') }
    it { is_expected.to include("<b>Ratio:</b> #{described_class.ratio(rates)}%") }
    it { is_expected.to include("<b>50K amount:</b> $#{described_class.max_to_buy(rates)}") }
    it { is_expected.to include("<b>To sell:</b> $#{described_class.sell_to_limit(rates)}") }
    it { is_expected.to include("<b>Diff:</b> $#{described_class.conversion_diff(rates)}") }
  end
end
