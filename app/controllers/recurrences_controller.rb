class RecurrencesController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_recurrence, only: %i[ show edit update finish ]
  before_action :prepare_categories, only: %i[ new create edit update ]

  def index
    @recurrences = @budget.recurrences.includes(:category)
      .order(ended_at: :asc, occurs_on: :asc, created_at: :asc)
  end

  def show; end

  def new
    @recurrence = @budget.recurrences.new(currency_code: @budget.base_currency_code,
      occurs_on: Date.current, occurrence_period_in_days: 30)
  end

  def create
    @recurrence = @budget.recurrences.new(recurrence_params)
    if @recurrence.save_with_category
      redirect_to budget_lenses_path(@budget), notice: t("recurrences.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @recurrence.assign_attributes(recurrence_params)
    if @recurrence.save_with_category
      redirect_to recurrence_path(@recurrence), notice: t("recurrences.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def finish
    @recurrence.end!
    redirect_to budget_recurrences_path(@budget), notice: t("recurrences.finish.success")
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def set_recurrence
      @recurrence = Recurrence.where(budget: Current.user.budgets).find(params[:id])
      @budget = @recurrence.budget
    end

    def prepare_categories
      @categories = @budget.categories.active.order(:name)
    end

    def recurrence_params
      params.require(:recurrence).permit(:name, :amount, :currency_code, :category_id, :category_name_to_create,
        :category_icon, :category_colour, :occurs_on, :occurrence_period_in_days, :note)
    end
end
