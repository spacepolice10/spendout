module Recordable
  extend ActiveSupport::Concern

  included do
    has_one :record, as: :recordable, dependent: :destroy, inverse_of: :recordable
    after_create :create_budget_record
  end

  private
    def create_budget_record
      create_record!(budget:, occurred_on:, created_at:, updated_at:)
    end
end
