class AllocationsController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_allocation, only: :show

  def index
    @allocations = @budget.allocations.where(deleted_at: nil).order(:created_at, :id)
  end

  def show
  end

  def new
    @allocation = @budget.allocations.new(currency_code: @budget.base_currency_code)
  end

  def create
    @allocation = @budget.allocations.new(allocation_params)

    if @allocation.save
      notice = if @budget.overallocated?
        "Allocation was created. Planned allocations now exceed available sources."
      else
        "Allocation was created."
      end
      redirect_to @allocation, notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def set_allocation
      @allocation = Allocation.where(budget: Current.user.budgets).find(params[:id])
      @budget = @allocation.budget
    end

    def allocation_params
      params.require(:allocation).permit(:name, :amount, :currency_code, :icon, :colour)
    end
end
