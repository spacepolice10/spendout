class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[ show destroy ]

  def index
    active, archived = Current.user.budgets.order(created_at: :desc).partition { |budget| !budget.archived? }
    @budgets = active + archived
  end

  def show
  end

  def new
    @budget = Current.user.budgets.new(period_from: Date.current, source_amount: 0)
  end

  def create
    @budget = Current.user.budgets.new(budget_params)

    if @budget.save_with_base_source
      redirect_to @budget, notice: "Budget was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @budget.destroy!
    redirect_to budgets_path, notice: "Budget was deleted."
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:id])
    end

    def budget_params
      params.require(:budget).permit(
        :period_from,
        :duration,
        :currency_code,
        :source_amount
      )
    end
end
