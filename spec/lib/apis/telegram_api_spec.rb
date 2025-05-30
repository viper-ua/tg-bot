# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Apis::TelegramApi do
  subject(:telegram_api) { described_class.new(bot_token:) }

  let(:bot_token) { ENV.fetch('TELEGRAM_TOKEN') }
  let(:chat_id) { ENV.fetch('TELEGRAM_CHAT_ID') }
  let(:images) { [File.expand_path('../../fixtures/test_image.png', __dir__)] }
  let(:message) { 'Hello from VCR test!' }

  describe '.send_media_message' do
    it 'delegates to an instance method' do
      expect_any_instance_of(described_class).to receive(:send_media_message)
      described_class.send_media_message(images:, message:, chat_id:)
    end
  end

  describe '#send_media_message', :vcr do
    it 'successfully sends a media group message to Telegram' do
      response = telegram_api.send_media_message(images:, message:, chat_id:)
      expect(response).to contain_exactly(Telegram::Bot::Types::Message)
    end
  end

  describe '.send_message' do
    it 'delegates to an instance method' do
      expect_any_instance_of(described_class).to receive(:send_message)
      described_class.send_message(text: message, chat_id:)
    end
  end

  describe '#send_message', :vcr do
    it 'successfully sends a text message to Telegram' do
      response = telegram_api.send_message(text: message, chat_id:)
      expect(response).to match(Telegram::Bot::Types::Message)
    end
  end

  describe '#compose_media_group', :aggregate_failures do
    it 'returns a hash with media array and files' do
      result = telegram_api.send(:compose_media_group, images:, message:)
      expect(result).to be_a(Hash)
      expect(result[:media]).to be_an(Array)
      expect(result[:media].size).to eq(images.size)
      images.each do |image|
        image_name = File.basename(image)
        expect(result[image_name]).not_to be_nil
      end
    end
  end

  describe '#media_definition', :aggregeate_failures do
    it 'returns an InputMediaPhoto object with correct values' do
      media = telegram_api.send(:media_definition, image_name: 'foo.png', message:)
      expect(media).to be_a(Telegram::Bot::Types::InputMediaPhoto)
      expect(media.caption).to eq(message)
      expect(media.media).to eq('attach://foo.png')
      expect(media.parse_mode).to eq('HTML')
    end
  end
end
