class RecurringOccurrence < ApplicationRecord
  belongs_to :recurrence
  belongs_to :expense

  validates :due_on, presence: true, uniqueness: { scope: :recurrence_id }
  validate :expense_matches_item

  private
    def expense_matches_item
      return unless expense && recurrence
      errors.add(:expense, :wrong_budget) if expense.budget_id != recurrence.budget_id
      errors.add(:expense, :category_mismatch) if expense.category_id != recurrence.category_id
    end
end
