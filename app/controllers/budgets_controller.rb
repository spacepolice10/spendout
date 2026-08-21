class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[ show destroy ]

  def current
    if budget = Current.user.current_budget
      redirect_to budget
    else
      redirect_to new_budget_path
    end
  end

  def show
    if @budget.archived?
      redirect_to Current.user.current_budget || new_budget_path
      return
    end

    @expenses = @budget.expenses.includes(:source, :allocation)
      .order(occurred_on: :desc, created_at: :desc, id: :desc)
    @expenses_by_date = @expenses.group_by(&:occurred_on)
    @expense_totals_by_date = @expenses_by_date.transform_values do |expenses|
      expenses.sum(&:amount_in_base)
    end
  end

  def new
    if budget = Current.user.current_budget
      redirect_to budget
    else
      @budget = Current.user.budgets.new(period_from: Date.current)
    end
  end

  def create
    @budget = Current.user.budgets.new(budget_params)

    if @budget.save_with_base_source
      redirect_to allocations_path, notice: "Budget was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @budget.destroy!
    redirect_to new_budget_path, notice: "Budget was reset."
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
        :source_amount,
        :source_rate
      )
    end
end
