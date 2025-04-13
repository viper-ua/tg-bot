# frozen_string_literal: true

FactoryBot.define do
  factory :currency_rate do
    buy { 40.5 }
    sell { 41.0 }
    created_at { Time.now }
  end
end
