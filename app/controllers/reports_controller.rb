class ReportsController < ApplicationController
  def show
    @budget = Current.user.budgets.find(params[:budget_id])
    @expenses = @budget.expenses.includes(:source, category: :allocation).where(occurred_on: @budget.period_from..@budget.period_to).to_a
    @spending_by_category = @expenses.group_by(&:category).map do |category, expenses|
      { category:, allocation: category.allocation, name: category.name,
        amount: expenses.sum(BigDecimal("0"), &:amount_in_base_currency), expense_number: expenses.size }
    end.sort_by { |item| [ -item[:amount], item[:name] ] }
    @most_expensive_category = @spending_by_category.first
    @totals_expenses = @expenses.sum(BigDecimal("0"), &:amount_in_base_currency)
    elapsed_to = [ @budget.period_to, Date.current ].min
    elapsed_days = elapsed_to < @budget.period_from ? 0 : (elapsed_to - @budget.period_from + 1).to_i
    @everyday_average = elapsed_days.positive? ? @totals_expenses / elapsed_days : BigDecimal("0")
    @largest_expense = @expenses.max_by(&:amount_in_base_currency)
    totals_by_date = @expenses.group_by(&:occurred_on).transform_values do |expenses|
      expenses.sum(BigDecimal("0"), &:amount_in_base_currency)
    end
    maximum = totals_by_date.values.max || BigDecimal("0")
    @spending_calendar = (@budget.period_from..@budget.period_to).map do |date|
      amount = totals_by_date.fetch(date, BigDecimal("0"))
      { date:, amount:, intensity: spending_intensity(amount, maximum) }
    end
  end

  private
    def spending_intensity(amount, maximum)
      return 0 unless amount.positive?
      return 4 if amount == maximum
      return 3 if amount >= maximum * BigDecimal("0.6667")
      return 2 if amount >= maximum * BigDecimal("0.3333")

      1
    end
end
