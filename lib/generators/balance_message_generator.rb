# frozen_string_literal: true

# Class responsible for generating balance report messages
class BalanceMessageGenerator
  class << self
    def message(balances:)
      <<~MESSAGE
        <b><i>#{Time.now}</i></b>
        #{balances.map { |acc| format_account(acc) }.join}
      MESSAGE
    end

    private

    def format_account(account)
      balance = format_amount(account['balance'] - account['creditLimit'])
      credit_limit = format_amount(account['creditLimit']) if account['creditLimit'].positive?

      <<~ACCOUNT
        <b>#{account['type']}}:</b> #{balance}#{credit_limit ? " (#{credit_limit})" : ''}
      ACCOUNT
    end

    def format_amount(amount)
      amount = amount.to_f / 100 # Convert from cents to main currency
      format('%.2f', amount)
    end
  end
end
