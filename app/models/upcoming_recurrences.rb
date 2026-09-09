class UpcomingRecurrences < ApplicationRecord
  Snapshot = Data.define(:items, :on, :through)
  has_one :lens, as: :lensable

  def snapshot(budget:, on: Date.current)
    through = on.next_month

    Snapshot.new(items: budget.recurrences.active.includes(:category)
      .where(occurs_on: on..through)
      .order(:occurs_on, :created_at, :id).to_a, on:, through:)
  end
end
