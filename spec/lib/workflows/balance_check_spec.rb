# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Workflows::BalanceCheck do
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:test_run) { false }

  before do
    allow(Apis::TelegramApi).to receive(:send_message)
  end

  describe '.run', :aggregate_failures do
    subject(:run_balance_check) { described_class.run(logger:, test_run:) }

    context 'when successful', :vcr do
      it 'fetches balances and sends message' do
        run_balance_check

        expect(Apis::TelegramApi).to have_received(:send_message).with(hash_including(:text))
        expect(logger).to have_received(:info).with(hash_including(:balances, :test_run))
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
        run_balance_check

        expect(logger).to have_received(:error).with(/StandardError - API Error/)
        expect(Apis::TelegramApi).not_to have_received(:send_message)
      end
    end

    context 'when test_run is true' do
      let(:test_run) { true }

      before do
        allow(Apis::MonoApi).to receive(:new).and_call_original
      end

      it 'passes test_run flag to MonoApi and sends a message' do
        run_balance_check

        expect(Apis::MonoApi).to have_received(:new).with(hash_including(test_run: true))
        expect(logger).to have_received(:info).with(hash_including(test_run: true))
        expect(Apis::TelegramApi).to have_received(:send_message).with(hash_including(:text))
      end
    end
  end

  describe '#run', :aggregate_failures do
    subject(:run_instance) { described_class.new(logger:, test_run:).run }

    context 'when successful', :vcr do
      it 'sets balances instance variable' do
        run_instance

        expect(logger).to have_received(:info).with(hash_including(:balances, :test_run))
        expect(Apis::TelegramApi).to have_received(:send_message).with(hash_including(:text))
      end
    end
  end
end
