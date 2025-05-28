# frozen_string_literal: true

require 'telegram/bot'

# Class implementing different Telegram API endpoints
class TelegramApi
  def self.send_message(...) = new.send_message(...)

  def initialize(bot_token: ENV.fetch('TELEGRAM_TOKEN', nil))
    @bot_token = bot_token
  end

  attr_reader :bot_token
  private :bot_token

  def send_message(message:, images: [], chat_id: ENV.fetch('TELEGRAM_CHAT_ID', nil))
    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.api.send_media_group(
        { chat_id: }.merge(compose_media_group(images:, message:))
      )
    end
  end

  private

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
