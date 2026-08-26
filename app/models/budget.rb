class Budget < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy, inverse_of: :budget
  has_many :allocations, dependent: :destroy, inverse_of: :budget
  has_many :exchanges, dependent: :destroy, inverse_of: :budget
  has_many :sources, dependent: :destroy, inverse_of: :budget

  alias_attribute :starts_date, :period_from
  alias_attribute :ends_date, :period_to

  validates :starts_date, :ends_date, presence: true
  validates :base_currency_code, inclusion: { in: Currency::CATALOG.keys }
  validate :period_starts_before_ends
  validate :single_current_budget_possible, on: :create
  validate :base_currency_cannot_change, on: :update

  def name
    return unless period_from && period_to

    if period_from.year != period_to.year
      "#{format_date(period_from, include_year: true)} – #{format_date(period_to, include_year: true)}"
    elsif period_from.month != period_to.month
      "#{format_date(period_from)} – #{format_date(period_to, include_year: true)}"
    else
      "#{format_date(period_from)} – #{period_to.strftime("%-d, %Y")}"
    end
  end

  def archived?
    period_to.present? && period_to < Date.current
  end

  def currency_code
    base_currency_code
  end

  def base_currency_metadata
    Currency.find!(base_currency_code)
  end

  def base_currency_symbol
    base_currency_metadata[:symbol]
  end

  def sources_amount_in_base
    active_sources = sources.where(deleted_at: nil)
    exchanged_amount_in_base = exchanges
      .joins(:parent_source)
      .where(sources: { deleted_at: nil })
      .pluck(:parent_amount, "sources.rate")
      .sum(BigDecimal("0")) { |amount, rate| amount / rate }

    amount_in_base_of(active_sources) - exchanged_amount_in_base
  end

  def allocations_amount_in_base
    allocations.planned.where(deleted_at: nil).includes(:expenses).sum(BigDecimal("0")) do |allocation|
      reserved_amount = allocation.finished? ? [ allocation.spent_amount, allocation.amount ].min : allocation.amount
      reserved_amount / allocation.rate
    end
  end

  def expenses_amount_in_base
    amount_in_base_of(expenses.joins(:source).where(sources: { deleted_at: nil }))
  end

  def unallocated_expenses_amount_in_base
    amount_in_base_of(
      expenses
        .joins(:source)
        .left_outer_joins(:allocation)
        .where(sources: { deleted_at: nil })
        .where("expenses.allocation_id IS NULL OR allocations.planned = ?", false)
    )
  end

  def amount_summary
    sources_amount_in_base - allocations_amount_in_base
  end

  def overallocated?
    allocations_amount_in_base > sources_amount_in_base
  end

  def overallocated_by
    [ allocations_amount_in_base - sources_amount_in_base, BigDecimal("0") ].max
  end

  def available_summary
    sources_amount_in_base - expenses_amount_in_base
  end

  def sources_remainder_in_base
    active_sources = sources.where(deleted_at: nil).includes(:expenses, :outgoing_exchanges)
    source_balances = active_sources.sum(BigDecimal("0")) do |source|
      source.spendable_amount / source.rate
    end

    remaining_plans = allocations.planned.active.includes(expenses: :source)
      .sum(BigDecimal("0")) do |allocation|
        spent_from_active_sources = allocation.expenses.sum(BigDecimal("0")) do |expense|
          expense.source.deleted? ? BigDecimal("0") : expense.source_amount / expense.source_rate
        end
        [ allocation.amount_in_base - spent_from_active_sources, BigDecimal("0") ].max
      end

    source_balances - remaining_plans
  end

  def last_expense_currency_code
    expenses.order(created_at: :desc, id: :desc).pick(:currency_code)
  end

  def todays_remainder
    return unless period_from <= Date.current && Date.current <= period_to

    daily_target = amount_summary / period_days
    planned_remainder = daily_target * days_elapsed - unallocated_expenses_amount_in_base
    actual_remainder = available_summary

    [ planned_remainder, actual_remainder ].min
  end

  def todays_remainder_percentage
    remainder = todays_remainder
    return unless remainder

    daily_target = amount_summary / period_days
    planned_opening_remainder = daily_target * days_elapsed -
      unallocated_expenses_amount_in_base + todays_unallocated_expenses_amount_in_base
    actual_opening_remainder = available_summary + todays_expenses_amount_in_base
    opening_remainder = [ planned_opening_remainder, actual_opening_remainder ].min
    return BigDecimal("0") unless opening_remainder.positive?

    [ [ remainder / opening_remainder * 100, BigDecimal("0") ].max, BigDecimal("100") ].min
  end

  def days_before_archived
    return if archived?

    (period_to - Date.current + 1).to_i
  end

  def days_elapsed
    return unless period_from && Date.current >= period_from

    [ (Date.current - period_from + 1).to_i, period_days ].min
  end

  def currency_code=(value)
    self.base_currency_code = value
  end

  def base_currency_code=(value)
    super(value.to_s.strip.upcase.presence)
  end

  private
    def period_days
      (period_to - period_from + 1).to_i
    end

    def amount_in_base_of(records)
      table = records.klass.arel_table

      records.pluck(table[:amount], table[:rate]).sum(BigDecimal("0")) do |amount, rate|
        amount / rate
      end
    end

    def todays_expenses_amount_in_base
      amount_in_base_of(
        expenses
          .joins(:source)
          .where(occurred_on: Date.current, sources: { deleted_at: nil })
      )
    end

    def todays_unallocated_expenses_amount_in_base
      amount_in_base_of(
        expenses
          .joins(:source)
          .left_outer_joins(:allocation)
          .where(occurred_on: Date.current, sources: { deleted_at: nil })
          .where("expenses.allocation_id IS NULL OR allocations.planned = ?", false)
      )
    end

    def period_starts_before_ends
      return unless period_from && period_to

      errors.add(:period_to, "must be on or after the start date") if period_to < period_from
    end

    def single_current_budget_possible
      errors.add(:base, "An active budget already exists") if user&.current_budget
    end

    def base_currency_cannot_change
      errors.add(:base_currency_code, "cannot be changed") if will_save_change_to_base_currency_code?
    end

    def format_date(date, include_year: false)
      date.strftime(include_year ? "%b %-d, %Y" : "%b %-d")
    end
end
