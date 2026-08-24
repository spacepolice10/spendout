class ExpensesController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_expense, only: %i[ show destroy ]

  def index
    if @budget.archived?
      redirect_to Current.user.current_budget ? budget_expenses_path(Current.user.current_budget) : new_budget_path
      return
    end

    @expenses = set_page_and_extract_portion_from(
      @budget.expenses.includes(:source, :allocation)
        .order(occurred_on: :desc, created_at: :desc, id: :desc)
    )
    @expenses_by_date = @expenses.group_by(&:occurred_on)
    @expense_totals_by_date = @expenses_by_date.transform_values do |expenses|
      expenses.sum(&:amount_in_base)
    end
  end

  def new
    set_form_collections
    @expense = @budget.expenses.new(
      source: @active_sources.first,
      allocation: @active_allocations.first,
      currency_code: @active_sources.first&.currency_code,
      conversion_rate: 1,
      occurred_on: Date.current.clamp(@budget.period_from, @budget.period_to)
    )
  end

  def create
    set_form_collections
    @expense = @budget.expenses.new(expense_params)

    if @expense.save_with_source_capacity
      redirect_to budget_expenses_path(@budget), notice: "Expense was created."
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
    redirect_to budget_expenses_path(budget), notice: "Expense was deleted."
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
        :currency_code,
        :conversion_rate,
        :occurred_on,
        :note,
        :category_name_to_create
      )
    end

    def set_form_collections
      @active_sources = @budget.sources.where(deleted_at: nil).order(:created_at, :id)
      @active_allocations = @budget.allocations.where(deleted_at: nil).order(:created_at, :id)
      @expense_currency_context = @active_sources.each_with_object({}) do |source, context|
        context[source.id] = {
          currency: source.currency_code,
          rate: source.rate.to_s("F")
        }
      end
    end
end
