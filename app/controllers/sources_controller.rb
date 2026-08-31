class SourcesController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_source, only: %i[ show destroy ]

  def index
    @sources = @budget.sources.where(deleted_at: nil).order(:created_at, :id)
    @exchanges = set_page_and_extract_portion_from(
      @budget.exchanges.includes(:sender_source, :receiver_source).order(created_at: :desc, id: :desc)
    )
    @exchanges_by_date = @exchanges.group_by { |exchange| exchange.created_at.to_date }
  end

  def show
    @expenses = set_page_and_extract_portion_from(
      @source.expenses.includes(:source, :allocation)
        .order(occurred_on: :desc, created_at: :desc, id: :desc)
    )
    @expenses_by_date = @expenses.group_by(&:occurred_on)
    @expense_totals_by_date = @expenses_by_date.transform_values do |expenses|
      expenses.sum(&:source_amount)
    end
  end

  def new
    @source = @budget.sources.new(currency_code: @budget.base_currency_code)
  end

  def create
    @source = @budget.sources.new(source_params)

    if @source.save
      redirect_to budget_sources_path(@budget), notice: t("sources.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @source.update(deleted_at: Time.current)
      redirect_to budget_sources_path(@budget), notice: t("sources.destroy.success")
    else
      redirect_to budget_sources_path(@budget), alert: t("sources.destroy.failure")
    end
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def set_source
      @source = Source.where(budget: Current.user.budgets).find(params[:id])
      @budget = @source.budget
    end

    def source_params
      params.require(:source).permit(:name, :amount, :currency_code, :rate, :design)
    end
end
