class BudgetsController < ApplicationController
  before_action :set_budget, only: :destroy

  def current
    if budget = Current.user.current_budget
      redirect_to budget_expenses_path(budget)
    else
      redirect_to new_budget_path
    end
  end

  def new
    if budget = Current.user.current_budget
      redirect_to budget_expenses_path(budget)
    else
      @budget = Current.user.budgets.new(starts_date: Date.current)
    end
  end

  def create
    @budget = Current.user.budgets.new(budget_params)

    if Current.user.with_lock { @budget.save }
      redirect_to budget_sources_path(@budget), notice: t("budgets.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @budget.destroy!
    redirect_to new_budget_path, notice: t("budgets.destroy.success")
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:id])
    end

    def budget_params
      params.require(:budget).permit(
        :starts_date,
        :ends_date,
        :base_currency_code
      )
    end
end
