# frozen_string_literal: true

require 'faraday'
require 'telegram/bot'

# Class implementing different Telegram API endpoints
class TelegramApi
  def self.send_message(...) = new.send_message(...)

  def initialize(bot_token: ENV['TELEGRAM_TOKEN'])
    @bot_token = bot_token
  end

  attr_reader :bot_token
  private :bot_token

  def send_message(chat_id: ENV['TELEGRAM_CHAT_ID'], images:, message:)
    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.api.send_media_group(
        { chat_id: }.merge(compose_media_group(images:, message:))
      )
    end
  end

  private

  def compose_media_group(images:, message:)
    empty_group = { media: [] }
    images.inject(empty_group) do |group, image_name|
      group[:media] << media_definition(image_name:, message:)
      group[image_name] = Faraday::UploadIO.new(image_name, 'image/png')
      group
    end
  end

  def media_definition(image_name:, message:)
    Telegram::Bot::Types::InputMediaPhoto.new(
      caption: message,
      media: "attach://#{image_name}",
      parse_mode: 'HTML',
      show_caption_above_media: true
    )
  end
end