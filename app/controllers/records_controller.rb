class RecordsController < ApplicationController
  include RecordTimeline

  before_action :set_budget

  def index
    if @budget.archived?
      redirect_to Current.user.current_budget ? budget_lenses_path(Current.user.current_budget) : new_budget_path
      return
    end

    unless turbo_frame_request?
      redirect_to budget_lenses_path(@budget)
      return
    end

    load_record_timeline
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end
end
