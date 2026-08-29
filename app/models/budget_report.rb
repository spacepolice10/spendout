class BudgetReport
  Category = Data.define(:allocation, :name, :amount, :expense_count)
  CalendarDay = Data.define(:date, :amount, :intensity)

  attr_reader :budget, :from, :to

  def initialize(budget, from: budget.starts_date, to: budget.ends_date)
    @budget = budget
    @from = from
    @to = to
  end

  def most_expensive_category
    spending_by_category.first
  end

  def spending_calendar
    @spending_calendar ||= begin
      totals = expenses.group_by(&:occurred_on).transform_values { |date_expenses| total(date_expenses) }
      maximum = totals.values.max || BigDecimal("0")

      (from..to).map do |date|
        amount = totals.fetch(date, BigDecimal("0"))
        CalendarDay.new(date:, amount:, intensity: spending_intensity(amount, maximum))
      end
    end
  end

  def spending_by_category
    @spending_by_category ||= expenses.group_by(&:allocation).map do |allocation, category_expenses|
      Category.new(
        allocation:,
        name: allocation&.name || "Uncategorized",
        amount: total(category_expenses),
        expense_count: category_expenses.size
      )
    end.sort_by { |category| [ -category.amount, category.name ] }
  end

  def total_expenses
    @total_expenses ||= total(expenses)
  end

  def daily_average
    return BigDecimal("0") unless elapsed_days.positive?

    total_expenses / elapsed_days
  end

  def largest_expense
    @largest_expense ||= expenses.max_by(&:amount_in_base_currency)
  end

  def transaction_count
    expenses.size
  end

  def remaining_general_funds
    budget.sources_remainder_in_base
  end

  private
    def expenses
      @expenses ||= budget.expenses
        .where(occurred_on: from..to)
        .includes(:source, :allocation)
        .to_a
    end

    def total(records)
      records.sum(BigDecimal("0"), &:amount_in_base_currency)
    end

    def spending_intensity(amount, maximum)
      return 0 unless amount.positive?
      return 4 if amount == maximum
      return 3 if amount >= maximum * BigDecimal("0.6667")
      return 2 if amount >= maximum * BigDecimal("0.3333")

      1
    end

    def elapsed_days
      elapsed_to = [ to, Date.current ].min
      return 0 if elapsed_to < from

      (elapsed_to - from + 1).to_i
    end
end
