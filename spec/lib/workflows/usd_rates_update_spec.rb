# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Workflows::UsdRatesUpdate do
  describe '.run', :aggregate_failures do
    subject(:run_workflow) { described_class.run(logger:, test_run:) }

    let(:logger) { instance_double(Logger, info: nil, error: nil) }
    let(:test_run) { false }

    before do
      allow(Apis::TelegramApi).to receive(:send_media_message).and_call_original
    end

    RSpec::Matchers.define :be_a_valid_currency_message do
      match do |message|
        message.include?('USD Buy:') &&
          message.include?('USD Sell:') &&
          message.include?('Ratio:') &&
          message.include?('50K amount:') &&
          message.include?('To sell:') &&
          message.include?('Diff:')
      end

      failure_message do |message|
        "expected #{message} to be a valid currency message"
      end
    end

    context 'when it is time to report' do
      before do
        Timecop.freeze(Time.local(2025, 5, 14, described_class::REPORTING_HOUR, 0, 0))
      end

      after do
        Timecop.return
      end

      it 'fetches rates, builds rate object, saves it, and sends a message', :vcr do
        expect { run_workflow }.to change(CurrencyRate, :count).by(1)

        expect(logger).to have_received(:info)
          .with(hash_including('buy' => 41.33, 'sell' => 41.8305, test_run: false))

        expect(Apis::TelegramApi).to have_received(:send_media_message)
          .with(images: %w[tmp/rates.png tmp/ratios.png tmp/diff.png], message: be_a_valid_currency_message)
      end
    end

    context 'when it is not time to report but rates are different' do
      before do
        Timecop.freeze(Time.local(2025, 5, 14, described_class::REPORTING_HOUR + 1, 0, 0))
      end

      after do
        Timecop.return
      end

      it 'fetches rates, builds rate object, saves it, and sends a message', :vcr do
        expect { run_workflow }.to change(CurrencyRate, :count).by(1)

        expect(logger).to have_received(:info)
          .with(hash_including('buy' => 41.33, 'sell' => 41.8305, test_run: false))

        expect(Apis::TelegramApi).to have_received(:send_media_message)
          .with(images: %w[tmp/rates.png tmp/ratios.png tmp/diff.png], message: be_a_valid_currency_message)
      end
    end

    context 'when it is not time to report and rates are the same' do
      before do
        Timecop.freeze(Time.local(2025, 5, 14, described_class::REPORTING_HOUR + 1, 0, 0))
        create(:currency_rate, buy: 41.33, sell: 41.8305, created_at: Time.now - 1.minute)
      end

      after do
        Timecop.return
      end

      it 'fetches rates, builds rate object, but does not save or send a message', :vcr do
        expect { run_workflow }.not_to change(CurrencyRate, :count)

        expect(logger).to have_received(:info)
          .with(hash_including('buy' => 41.33, 'sell' => 41.8305, test_run: false))

        expect(Apis::TelegramApi).not_to have_received(:send_media_message)
      end
    end

    context 'when it is a test run' do
      let(:test_run) { true }

      before do
        Timecop.freeze(Time.local(2025, 5, 14, described_class::REPORTING_HOUR + 1, 0, 0))
        create(:currency_rate, buy: 41.33, sell: 41.8305, created_at: Time.now - 1.minute)
      end

      after do
        Timecop.return
      end

      it 'returns random rates, builds rate object, but does not save it, and sends message' do
        expect { run_workflow }.not_to change(CurrencyRate, :count)

        expect(logger).to have_received(:info).with(hash_including(test_run: true))
        expect(Apis::TelegramApi).to have_received(:send_media_message)
          .with(images: %w[tmp/rates.png tmp/ratios.png tmp/diff.png], message: be_a_valid_currency_message)
      end
    end

    context 'when an error occurs during execution' do
      let(:error) { StandardError.new('Something went wrong') }
      let(:mocked_mono_api) { instance_double(Apis::MonoApi) }

      before do
        allow(Apis::MonoApi).to receive(:new).and_return(mocked_mono_api)
        allow(mocked_mono_api).to receive(:fetch_rates).and_raise(error)
        allow(error).to receive(:backtrace).and_return(['line 1', 'line 2'])
      end

      it 'logs the error and does not raise it' do
        expect { run_workflow }.not_to raise_error
        expect(logger).to have_received(:error).with("StandardError - Something went wrong\nline 1\nline 2")
      end

      it 'does not attempt to save or send message' do
        expect { run_workflow }.not_to change(CurrencyRate, :count)
        expect(Apis::TelegramApi).not_to have_received(:send_media_message)
      end
    end
  end
end
