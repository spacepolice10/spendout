class PlanOverview < ApplicationRecord
  Snapshot = Data.define(:currency_code, :allocated_amount, :used_amount, :remaining_amount, :records)

  has_one :lens, as: :lensable

  def snapshot(budget:, on: Date.current)
    records = budget.allocations.includes(:category, expenses: :source).where(deleted_at: nil).order(:created_at, :id).to_a
    allocated = records.sum(BigDecimal("0"), &:amount_in_base_currency)
    used = records.sum(BigDecimal("0")) { |allocation| allocation.used_amount / allocation.rate }
    Snapshot.new(currency_code: budget.base_currency_code, allocated_amount: allocated,
      used_amount: used, remaining_amount: [ allocated - used, BigDecimal("0") ].max, records:)
  end
end
