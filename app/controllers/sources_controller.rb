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
  end

  def new
    @source = @budget.sources.new(currency_code: @budget.base_currency_code)
  end

  def create
    @source = @budget.sources.new(source_params)

    if @source.save
      redirect_to budget_sources_path(@budget), notice: "Source was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @source.update(deleted_at: Time.current)
      redirect_to budget_sources_path(@budget), notice: "Source was deleted."
    else
      redirect_to budget_sources_path(@budget), alert: "Source was not deleted."
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
      params.require(:source).permit(:name, :amount, :currency_code, :rate, :icon, :colour)
    end
end
