class Record < ApplicationRecord
  delegated_type :recordable, types: %w[ Expense Income ]
  belongs_to :budget, inverse_of: :records

  scope :chronological, -> { order(occurred_on: :desc, created_at: :desc, id: :desc) }

  def self.preload_recordables(records)
    records = records.to_a
    ActiveRecord::Associations::Preloader.new(records:, associations: [ :recordable ]).call if records.any?
    expenses = records.select(&:expense?).map(&:recordable)
    incomes = records.select(&:income?).map(&:recordable)
    ActiveRecord::Associations::Preloader.new(records: expenses, associations: [ :source, :category ]).call if expenses.any?
    ActiveRecord::Associations::Preloader.new(records: incomes, associations: [ :source ]).call if incomes.any?
    records
  end

  def self.display_total(records)
    spending = records.select(&:expense?).sum(BigDecimal("0"), &:amount_in_base_currency)
    spending.positive? ? spending : records.select(&:income?).sum(BigDecimal("0"), &:amount_in_base_currency)
  end

  def amount_in_base_currency = recordable.amount_in_base_currency
end
