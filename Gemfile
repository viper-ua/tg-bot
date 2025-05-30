# frozen_string_literal: true

source 'https://rubygems.org'

group :production do
  gem 'activerecord'
  gem 'faraday'
  gem 'gruff'
  gem 'rake'
  gem 'rufus-scheduler'
  gem 'sqlite3', '~> 2.0'
  gem 'telegram-bot-ruby'
  gem 'zeitwerk'
end

gem 'dotenv', groups: %i[development test]

group :development do
  gem 'pry-byebug'
  gem 'rubocop'
  gem 'rubocop-factory_bot'
  gem 'rubocop-rspec'
  gem 'rubycritic'
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'factory_bot'
  gem 'rspec'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end
