# frozen_string_literal: true

module Generators
  # Class responsible for generating balance report messages
  class BalanceMessage
    TYPES_MAPPING = {
      'yellow' => '👶 Дитяча',
      'eAid' => '🛟 єДопомога',
      'black' => '🐈‍⬛ Кредитка',
      'white' => '🐈 Біла'
    }.freeze

    def message(balances:)
      <<~MESSAGE.strip
        #{header}
        #{format_balances(balances)}
      MESSAGE
    end

    private

    def header
      "<b><i>#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</i></b>"
    end

    def format_balances(balances)
      balances.map { |account| format_account(account) }.join
    end

    def format_account(account)
      balance = format_amount(account['balance'] - account['creditLimit'])
      credit_limit = format_credit_limit(account['creditLimit'])
      account_type = format_type(account['type'])

      <<~ACCOUNT
        <b>#{account_type}:</b> #{balance}#{credit_limit}
      ACCOUNT
    end

    def format_credit_limit(credit_limit)
      return '' unless credit_limit.positive?

      " (#{format_amount(credit_limit)})"
    end

    def format_amount(amount)
      amount = amount.to_f / 100 # Convert from cents to main currency
      format('%.2f', amount)
    end

    def format_type(type)
      TYPES_MAPPING[type] || type
    end
  end
end
