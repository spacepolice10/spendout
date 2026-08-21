class Budget < ApplicationRecord
  DURATIONS = {
    "14_days" => 14,
    "30_days" => 30,
    "90_days" => 90
  }.freeze

  belongs_to :user
  has_many :expenses, dependent: :destroy, inverse_of: :budget
  has_many :allocations, dependent: :destroy, inverse_of: :budget
  has_many :sources, dependent: :destroy, inverse_of: :budget

  attribute :duration, :string, default: "30_days"
  attribute :currency_code, :string
  attribute :source_amount, :decimal
  attribute :source_rate, :decimal, default: 1

  before_validation :calculate_period_to, on: :create

  validates :period_from, :period_to, presence: true
  validates :duration, inclusion: { in: DURATIONS.keys }
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }, on: :create
  validates :source_amount, numericality: { greater_than_or_equal_to: 0 }, on: :create
  validates :source_rate, numericality: { equal_to: 1 }, on: :create
  validate :period_starts_before_ends
  validate :single_current_budget_possible, on: :create

  def save_with_base_source
    user.with_lock do
      sources.build(amount: source_amount, currency_code: currency_code, rate: source_rate)
      save
    end
  end

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

  def base_currency_code
    base_source&.currency_code
  end

  def base_currency_metadata
    Currency.find!(base_currency_code)
  end

  def base_currency_symbol
    base_currency_metadata[:symbol]
  end

  def base_source
    sources.order("sources.created_at ASC", "sources.id ASC").first
  end

  def sources_amount_in_base
    amount_in_base_of(sources.where(deleted_at: nil))
  end

  def allocations_amount_in_base
    amount_in_base_of(allocations.planned.where(deleted_at: nil))
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
    return BigDecimal("0") unless daily_target.positive?

    [ [ remainder / daily_target * 100, BigDecimal("0") ].max, BigDecimal("100") ].min
  end

  def days_until_archived
    return if archived?

    (period_to - Date.current + 1).to_i
  end

  def days_elapsed
    return unless period_from && Date.current >= period_from

    [ (Date.current - period_from + 1).to_i, period_days ].min
  end

  def currency_code=(value)
    super(value.to_s.strip.upcase.presence)
  end

  private
    def period_days
      (period_to - period_from + 1).to_i
    end

    def amount_in_base_of(records)
      table = records.klass.arel_table

      records.pluck(table[:amount], table[:rate]).sum(BigDecimal("0")) do |amount, rate|
        amount * rate
      end
    end

    def calculate_period_to
      days = DURATIONS[duration]
      self.period_to = period_from + days - 1 if period_from && days
    end

    def period_starts_before_ends
      return unless period_from && period_to

      errors.add(:period_to, "must be on or after the start date") if period_to < period_from
    end

    def single_current_budget_possible
      errors.add(:base, "An active budget already exists") if user&.current_budget
    end

    def format_date(date, include_year: false)
      date.strftime(include_year ? "%b %-d, %Y" : "%b %-d")
    end
end
