# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Workflows::BalanceCheck do
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:test_run) { false }

  describe '.run' do
    subject(:run_balance_check) { described_class.run(logger:, test_run:) }

    context 'when successful', :vcr do
      it 'fetches balances and sends message' do
        expect(logger).to receive(:info).with(hash_including(:balances, :test_run))
        expect(Apis::TelegramApi).to receive(:send_message).with(hash_including(:text))

        run_balance_check
      end
    end

    context 'when MonoApi raises an error' do
      let(:error) { StandardError.new('Something went wrong') }
      let(:mocked_mono_api) { instance_double(Apis::MonoApi) }

      before do
        allow(Apis::MonoApi).to receive(:new).and_return(mocked_mono_api)
        allow(mocked_mono_api).to receive(:fetch_balances)
          .and_raise(StandardError.new('API Error'))
      end

      it 'logs the error and does not send message' do
        expect(logger).to receive(:error).with(/StandardError - API Error/)
        expect(Apis::TelegramApi).not_to receive(:send_message)

        run_balance_check
      end
    end

    context 'when test_run is true' do
      let(:test_run) { true }

      it 'passes test_run flag to MonoApi and sends a message' do
        expect(Apis::MonoApi).to receive(:new)
          .with(hash_including(test_run: true)).and_call_original
        expect(logger).to receive(:info).with(hash_including(test_run: true))
        expect(Apis::TelegramApi).to receive(:send_message).with(hash_including(:text))

        run_balance_check
      end
    end
  end

  describe '#run' do
    subject(:run_instance) { described_class.new(logger:, test_run:).run }

    context 'when successful', :vcr do
      it 'sets balances instance variable' do
        expect(logger).to receive(:info).with(hash_including(:balances, :test_run))
        expect(Apis::TelegramApi).to receive(:send_message).with(hash_including(:text))

        run_instance
      end
    end
  end
end
