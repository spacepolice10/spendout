class RecentRecords
  DayInsight = Data.define(:unusual_multiple, :plan_breaks)
  PlanBreak = Data.define(:category, :occurrences, :spent, :planned)
  Snapshot = Data.define(:currency_code, :records, :records_by_date, :totals_by_date, :insights_by_date)

  def snapshot(budget:, records:, on: Date.current)
    records = Record.preload_recordables(records)
    through = [ on, budget.period_to ].min
    all_expenses = budget.expenses.includes(:source, :category)
      .where(occurred_on: budget.period_from..through).to_a
    by_date = records.group_by(&:occurred_on)
    totals_by_date = totals_by_date_for(budget, by_date.keys)
    all_totals_by_date = all_expenses.group_by(&:occurred_on).transform_values { |expenses| total(expenses) }
    usual_day = median(all_totals_by_date.values)
    plan_breaks_by_date = plan_breaks_by_date(budget, all_expenses, visible_expense_dates(by_date))
    insights_by_date = by_date.to_h do |date, _day_records|
      day_total = all_totals_by_date.fetch(date, BigDecimal("0"))
      unusual_multiple = day_total / usual_day if usual_day.positive? && day_total > usual_day * BigDecimal("1.5")
      [ date, DayInsight.new(unusual_multiple:, plan_breaks: plan_breaks_by_date.fetch(date, [])) ]
    end

    Snapshot.new(currency_code: budget.base_currency_code, records:, records_by_date: by_date,
      totals_by_date:, insights_by_date:)
  end

  private
    def totals_by_date_for(budget, dates)
      return {} if dates.empty?

      Record.preload_recordables(
        budget.records.includes(:recordable).where(occurred_on: dates)
      ).group_by(&:occurred_on).transform_values { |records| Record.display_total(records) }
    end

    def visible_expense_dates(by_date)
      by_date.filter_map { |date, records| date if records.any?(&:expense?) }
    end

    def total(amounts)
      amounts.sum(BigDecimal("0"), &:amount_in_base_currency)
    end

    def median(amounts)
      return BigDecimal("0") if amounts.empty?

      amounts.sort[amounts.size / 2]
    end

    def plan_breaks_by_date(budget, expenses, visible_dates)
      expenses_by_category = expenses.group_by(&:category_id)

      budget.allocations.active.includes(:category).each_with_object(Hash.new { |hash, date| hash[date] = [] }) do |allocation, result|
        category_expenses = expenses_by_category.fetch(allocation.category_id, [])
        next unless category_expenses.size >= 2

        spent = total(category_expenses)
        planned = allocation.amount / allocation.rate
        next unless spent > planned

        latest_visible_date = category_expenses.map(&:occurred_on).select { |date| date.in?(visible_dates) }.max
        next unless latest_visible_date

        result[latest_visible_date] << PlanBreak.new(
          category: allocation.category, occurrences: category_expenses.size, spent:, planned:
        )
      end
    end
end
