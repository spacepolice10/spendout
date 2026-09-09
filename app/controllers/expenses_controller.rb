class ExpensesController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_expense, only: %i[ show destroy ]

  def index
    if @budget.archived?
      redirect_to Current.user.current_budget ? budget_expenses_path(Current.user.current_budget) : new_budget_path
      return
    end

    @expenses = set_page_and_extract_portion_from(
      @budget.expenses.includes(:source, :category)
        .order(occurred_on: :desc, created_at: :desc, id: :desc)
    )
    @expenses_by_date = @expenses.group_by(&:occurred_on)
    @expense_totals_by_date = @expenses_by_date.transform_values do |expenses|
      expenses.sum(&:amount_in_base_currency)
    end
  end

  def new
    predefine_form_collections
    item = recurrence
    @expense = @budget.expenses.new(
      source: @active_sources.first,
      category: item&.category || @active_categories.first,
      currency_code: @active_sources.first&.currency_code,
      conversion_rate: 1,
      occurred_on: item&.occurs_on || Date.current.clamp(@budget.period_from, @budget.period_to),
      amount: item&.amount,
      note: item&.note,
      recurrence_id: item&.id
    )
  end

  def create
    predefine_form_collections
    @expense = @budget.expenses.new(expense_params)

    if save_expense_and_occurrence
      redirect_to budget_lenses_path(@budget), notice: t("expenses.create.success")
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
    redirect_to budget_expenses_path(budget), notice: t("expenses.destroy.success")
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
        :category_id,
        :amount,
        :currency_code,
        :conversion_rate,
        :occurred_on,
        :note,
        :category_name_to_create,
        :recurrence_id
      )
    end

    def predefine_form_collections
      @active_sources = @budget.sources.where(deleted_at: nil).order(:created_at, :id)
      @active_categories = @budget.categories.active.order(:created_at, :id)
      @expense_currency_context = @active_sources.each_with_object({}) do |source, context|
        context[source.id] = {
          currency: source.currency_code,
          rate: source.rate.to_s("F")
        }
      end
    end

    def recurrence
      return unless params[:recurrence_id].present?

      @recurrence ||= @budget.recurrences.active.find(params[:recurrence_id])
    end

    def save_expense_and_occurrence
      item = @budget.recurrences.active.find(@expense.recurrence_id) if @expense.recurrence_id.present?
      return @expense.save_with_source_capacity unless item

      Expense.transaction do
        @expense.category = item.category
        saved = @expense.save_with_source_capacity
        item.record!(@expense) if saved
        saved
      end
    end
end
