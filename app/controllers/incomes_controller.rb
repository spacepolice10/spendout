class IncomesController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_income, only: %i[ show destroy ]

  def index
    @incomes = @budget.incomes.includes(:source).order(occurred_on: :desc, created_at: :desc, id: :desc)
    @incomes_by_date = @incomes.group_by(&:occurred_on)
  end

  def new
    @sources = active_sources
    @income = @budget.incomes.new(source: @sources.first, currency_code: @sources.first&.currency_code,
      conversion_rate: 1, occurred_on: Date.current.clamp(@budget.period_from, @budget.period_to))
  end

  def create
    @sources = active_sources
    @income = @budget.incomes.new(income_params)
    if @income.save
      redirect_to budget_lenses_path(@budget), notice: t("incomes.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @budget = @income.budget
  end

  def destroy
    budget = @income.budget
    if @income.destroy_with_source_lock
      redirect_to budget_incomes_path(budget), notice: t("incomes.destroy.success")
    else
      redirect_to income_path(@income), alert: t("incomes.destroy.failure")
    end
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def set_income
      @income = Income.where(budget: Current.user.budgets).find(params[:id])
    end

    def active_sources = @budget.sources.where(deleted_at: nil).order(:created_at, :id)

    def income_params
      params.require(:income).permit(:source_id, :source_name, :amount, :currency_code,
        :conversion_rate, :occurred_on, :note)
    end
end
