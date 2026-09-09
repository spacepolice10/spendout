class Cybercat
  Message = Data.define(:key, :options)
  Snapshot = Data.define(:time_of_day, :messages) do
    def featured_message
      time_of_day == :morning ? messages.second : messages.third
    end
  end

  def snapshot(budget:, on: Date.current)
    expenses_today = budget.expenses.includes(:source).where(occurred_on: on).to_a
    spent_today = expenses_today.sum(BigDecimal("0"), &:amount_in_base_currency)
    remainder = on == Date.current ? budget.todays_remainder : nil
    time_of_day = case Time.current.hour
    when 5...12 then :morning
    when 12...18 then :afternoon
    else :evening
    end

    messages = [ Message.new(key: time_of_day, options: {}) ]
    messages << if budget.sources.none?
      Message.new(key: :add_first_source, options: {})
    elsif budget.allocations.none?
      Message.new(key: :add_first_allocation, options: {})
    elsif remainder
      Message.new(key: remainder.negative? ? :over_pace : :remaining_today,
        options: { amount: remainder.abs, currency_code: budget.base_currency_code })
    else
      Message.new(key: :available,
        options: { amount: budget.available_summary, currency_code: budget.base_currency_code })
    end
    messages << if expenses_today.any?
      Message.new(key: :spent_today,
        options: { count: expenses_today.size, amount: spent_today, currency_code: budget.base_currency_code })
    else
      Message.new(key: :quiet_today, options: {})
    end

    Snapshot.new(time_of_day:, messages:)
  end
end
