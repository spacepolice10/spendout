class ExpensesController < ApplicationController
  before_action :set_budget, only: %i[ new create ]
  before_action :set_expense, only: %i[ show destroy ]

  def new
    @active_sources = @budget.sources.where(deleted_at: nil).order(:created_at, :id)
    @active_allocations = @budget.allocations.where(deleted_at: nil).order(:created_at, :id)
    source = @budget.base_source
    @expense = @budget.expenses.new(
      source: source,
      allocation: @active_allocations.first,
      occurred_on: Date.current.clamp(@budget.period_from, @budget.period_to)
    )
  end

  def create
    @active_sources = @budget.sources.where(deleted_at: nil).order(:created_at, :id)
    @active_allocations = @budget.allocations.where(deleted_at: nil).order(:created_at, :id)
    @expense = @budget.expenses.new(expense_params)

    if @expense.save_with_source_capacity
      redirect_to @budget, notice: "Expense was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @budget = @expense.budget
  end

  def destroy
    budget = @expense.budget
    @expense.destroy_with_source_lock!
    redirect_to budget, notice: "Expense was deleted."
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def set_expense
      @expense = Expense.where(budget: Current.user.budgets).find(params[:id])
    end

    def expense_params
      params.require(:expense).permit(
        :source_id,
        :allocation_id,
        :amount,
        :occurred_on,
        :note,
        :category_name_to_create
      )
    end
end
