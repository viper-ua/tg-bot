# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Apis::TelegramApi do
  subject(:telegram_api) { described_class.new(bot_token:) }

  let(:bot_token) { ENV.fetch('TELEGRAM_TOKEN') }
  let(:chat_id) { ENV.fetch('TELEGRAM_CHAT_ID') }
  let(:images) { [File.expand_path('../../fixtures/test_image.png', __dir__)] }
  let(:message) { 'Hello from VCR test!' }

  describe '.send_media_message' do
    let(:api_instance) do
      instance_double(
        described_class,
        send_media_message: [instance_double(Telegram::Bot::Types::Message)]
      )
    end

    it 'delegates to an instance method' do
      allow(described_class).to receive(:new).and_return(api_instance)
      described_class.send_media_message(images:, message:, chat_id:)
      expect(api_instance).to have_received(:send_media_message)
    end
  end

  describe '#send_media_message', :vcr do
    it 'successfully sends a media group message to Telegram' do
      response = telegram_api.send_media_message(images:, message:, chat_id:)
      expect(response).to contain_exactly(Telegram::Bot::Types::Message)
    end
  end

  describe '.send_message' do
    let(:api_instance) do
      instance_double(
        described_class,
        send_message: instance_double(Telegram::Bot::Types::Message)
      )
    end

    it 'delegates to an instance method' do
      allow(described_class).to receive(:new).and_return(api_instance)

      described_class.send_message(text: message, chat_id:)

      expect(api_instance).to have_received(:send_message)
    end
  end

  describe '#send_message', :vcr do
    it 'successfully sends a text message to Telegram' do
      response = telegram_api.send_message(text: message, chat_id:)
      expect(response).to match(Telegram::Bot::Types::Message)
    end
  end

  describe '#compose_media_group', :aggregate_failures do
    subject(:result) { telegram_api.send(:compose_media_group, images:, message:) }

    it 'returns a hash containing media array and file attachments' do
      expect(result).to be_a(Hash)
      expect(result[:media]).to be_an(Array)
      expect(result[:media].size).to eq(images.size)
    end

    it 'includes all image files as attachments' do
      images.each do |image|
        expect(result[File.basename(image)]).to be_a(Faraday::UploadIO)
      end
    end
  end

  describe '#media_definition', :aggregate_failures do
    it 'returns an InputMediaPhoto object with correct values' do
      media = telegram_api.send(:media_definition, image_name: 'foo.png', message:)
      expect(media).to be_a(Telegram::Bot::Types::InputMediaPhoto)
        .and have_attributes(
          caption: message,
          media: 'attach://foo.png',
          parse_mode: 'HTML'
        )
    end
  end
end
