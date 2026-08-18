class Budget < ApplicationRecord
  DURATIONS = {
    "14_days" => 14,
    "30_days" => 30
  }.freeze

  belongs_to :user
  has_many :currencies, dependent: :destroy, inverse_of: :budget
  has_many :allocations, dependent: :destroy, inverse_of: :budget
  has_many :sources, dependent: :destroy, inverse_of: :budget

  attribute :duration, :string, default: "30_days"
  attribute :currency_code, :string
  attribute :source_amount, :decimal

  before_validation :calculate_period_to, on: :create

  validates :period_from, :period_to, presence: true
  validates :duration, inclusion: { in: DURATIONS.keys }
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }, on: :create
  validates :source_amount, numericality: { greater_than_or_equal_to: 0 }, on: :create
  validates :currencies, :sources, presence: true, on: :create
  validate :period_starts_before_ends

  def save_with_base_source
    currencies.build(alphabetic_code: currency_code, rate: 1)
    sources.build(amount: source_amount, currency_code: currency_code)
    save
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

  def base_currency
    currencies.find_by(alphabetic_code: base_source&.currency_code)
  end

  def base_source
    sources.order("sources.created_at ASC", "sources.id ASC").first
  end

  def sources_amount_in_base
    amount_in_base_of(sources.where(deleted_at: nil))
  end

  def allocations_amount_in_base
    amount_in_base_of(allocations.where(deleted_at: nil))
  end

  def amount_summary
    sources_amount_in_base - allocations_amount_in_base
  end

  def currency_code=(value)
    super(value.to_s.strip.upcase.presence)
  end

  private
    def amount_in_base_of(records)
      currencies_by_code = currencies.index_by(&:alphabetic_code)

      records.group(:currency_code).sum(:amount).sum(BigDecimal("0")) do |currency_code, amount|
        currencies_by_code.fetch(currency_code).amount_in_base(amount)
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

    def format_date(date, include_year: false)
      date.strftime(include_year ? "%b %-d, %Y" : "%b %-d")
    end
end
