# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Generators::BalanceMessage do
  subject(:generator) { described_class.new }

  describe '#message' do
    let(:balances) do
      [
        {
          'type' => 'yellow',
          'balance' => 10_000, # 100.00
          'creditLimit' => 0
        },
        {
          'type' => 'eAid',
          'balance' => 5000, # 50.00
          'creditLimit' => 10_000 # 100.00
        },
        {
          'type' => 'black',
          'balance' => 20_000, # 200.00
          'creditLimit' => 50_000 # 500.00
        },
        {
          'type' => 'white',
          'balance' => 15_000, # 150.00
          'creditLimit' => 0
        }
      ]
    end

    let(:current_time) { Time.new(2024, 3, 20, 12, 0, 0) }

    before do
      allow(Time).to receive(:now).and_return(current_time)
    end

    it 'generates a properly formatted message' do
      expected_message = <<~MESSAGE.strip
        <b><i>2024-03-20 12:00:00</i></b>
        <b>👶 Дитяча:</b> 100.00
        <b>🛟 єДопомога:</b> -50.00 (100.00)
        <b>🐈‍⬛ Кредитка:</b> -300.00 (500.00)
        <b>🐈 Біла:</b> 150.00
      MESSAGE

      expect(generator.message(balances: balances)).to eq(expected_message)
    end

    context 'with empty balances' do
      it 'returns only the header' do
        expected_message = <<~MESSAGE.strip
          <b><i>2024-03-20 12:00:00</i></b>
        MESSAGE

        expect(generator.message(balances: [])).to eq(expected_message)
      end
    end

    context 'with unknown account type' do
      let(:balances) do
        [
          {
            'type' => 'unknown',
            'balance' => 10_000,
            'creditLimit' => 0
          }
        ]
      end

      it 'handles unknown account type gracefully' do
        expected_message = <<~MESSAGE.strip
          <b><i>2024-03-20 12:00:00</i></b>
          <b>unknown:</b> 100.00
        MESSAGE

        expect(generator.message(balances: balances)).to eq(expected_message)
      end
    end
  end
end
