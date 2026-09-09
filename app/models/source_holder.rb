class SourceHolder < ApplicationRecord
  Record = Data.define(:id, :name, :design, :colour, :currency_code, :balance)
  Snapshot = Data.define(:currency_code, :total_balance, :records, :hidden_count)

  has_one :lens, as: :lensable

  def snapshot(budget:, on: Date.current)
    sources = budget.sources.where(deleted_at: nil).order(:created_at, :id).to_a
    records = sources.map do |source|
      Record.new(id: source.id, name: source.name, design: Source::DESIGNS.fetch(source.design),
        colour: source.colour, currency_code: source.currency_code, balance: source.spendable_amount)
    end
    total = sources.sum(BigDecimal("0")) { |source| source.spendable_amount / source.rate }
    Snapshot.new(currency_code: budget.base_currency_code, total_balance: total,
      records:, hidden_count: sources.size - records.size)
  end
end
