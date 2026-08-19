class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[ show destroy ]

  def index
    active, archived = Current.user.budgets.order(created_at: :desc).partition { |budget| !budget.archived? }
    @budgets = active + archived
  end

  def show
    @expenses = @budget.expenses.includes(:source, :allocation)
      .order(occurred_on: :desc, created_at: :desc, id: :desc)
    @expenses_by_date = @expenses.group_by(&:occurred_on)

    currencies_by_code = @budget.currencies.index_by(&:alphabetic_code)
    @expense_totals_by_date = @expenses_by_date.transform_values do |expenses|
      expenses.sum(BigDecimal("0")) do |expense|
        currencies_by_code.fetch(expense.currency_code).amount_in_base(expense.amount)
      end
    end
  end

  def new
    @budget = Current.user.budgets.new(period_from: Date.current)
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
