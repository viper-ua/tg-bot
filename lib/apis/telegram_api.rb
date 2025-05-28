# frozen_string_literal: true

require 'faraday'
require 'telegram/bot'

# Class implementing different Telegram API endpoints
# @example
#   TelegramApi.send_message(text: 'Hello!')
#   TelegramApi.send_media_message(message: 'Report', images: ['image1.png', 'image2.png'])
#
# @attr_reader bot_token [String] The Telegram bot token
class TelegramApi
  class << self
    def send_message(...) = new.send_message(...)
    def send_media_message(...) = new.send_media_message(...)
  end

  def initialize(bot_token: ENV.fetch('TELEGRAM_TOKEN', nil))
    @bot_token = bot_token
  end

  attr_reader :bot_token
  private :bot_token

  # Sends a media group message with images and text
  # @param message [String] The message text to send
  # @param images [Array<String>] Array of image file paths
  # @param chat_id [String] The chat ID to send the message to
  # @return [void]
  def send_media_message(message:, images:, chat_id: default_chat_id)
    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.api.send_media_group(
        { chat_id: }.merge(compose_media_group(images:, message:))
      )
    end
  end

  # Sends a text message
  # @param text [String] The message text to send
  # @param chat_id [String] The chat ID to send the message to
  # @return [void]
  def send_message(text:, chat_id: default_chat_id)
    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.api.send_message({ chat_id:, text: })
    end
  end

  private

  def default_chat_id
    ENV.fetch('TELEGRAM_CHAT_ID', nil)
  end

  def compose_media_group(images:, message:)
    empty_group = { media: [] }
    images.each_with_object(empty_group) do |image_path, group|
      image_name = File.basename(image_path)
      group[:media] << media_definition(image_name:, message:)
      group[image_name] = Faraday::UploadIO.new(image_path, 'image/png')
    end
  end

  def media_definition(image_name:, message:)
    Telegram::Bot::Types::InputMediaPhoto.new(
      caption: message,
      media: "attach://#{image_name}",
      parse_mode: 'HTML'
    )
  end
end
