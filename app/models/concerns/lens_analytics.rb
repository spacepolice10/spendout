module LensAnalytics
  extend ActiveSupport::Concern

  private
    def expense_records(budget, through: Date.current)
      budget.expenses.includes(:source, :category).where(occurred_on: budget.period_from..[ through, budget.period_to ].min).to_a
    end

    def total(records)
      records.sum(BigDecimal("0"), &:amount_in_base_currency)
    end

    def currency_amount_in_base(budget, amount, currency_code)
      return amount if currency_code == budget.base_currency_code

      rate = budget.sources.where(currency_code:).pick(:rate)
      rate && amount / rate
    end
end
