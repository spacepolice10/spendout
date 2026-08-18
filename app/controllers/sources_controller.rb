class SourcesController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_source, only: :show

  def index
    @sources = @budget.sources.where(deleted_at: nil).order(:created_at, :id)
  end

  def show
  end

  def new
    @source = @budget.sources.new(amount: 0, currency_code: @budget.base_currency.alphabetic_code)
  end

  def create
    @source = @budget.sources.new(source_params)

    if @source.save
      redirect_to @source, notice: "Source was created."
    else
      render :new, status: :unprocessable_entity
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
      params.require(:source).permit(:name, :amount, :currency_code, :icon, :colour)
    end
end
