class AllocationsController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_allocation, only: %i[ show destroy ]

  def index
    @allocations = @budget.allocations.where(deleted_at: nil, planned: true).order(:created_at, :id)
  end

  def show
  end

  def new
    @allocation = @budget.allocations.new(currency_code: @budget.base_currency_code, rate: 1)
  end

  def create
    @allocation = @budget.allocations.new(allocation_params)

    if @allocation.save
      notice = if @budget.overallocated?
        "Allocation was created. Planned allocations now exceed available sources."
      else
        "Allocation was created."
      end
      redirect_to budget_allocations_path(@budget), notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @allocation.update(deleted_at: Time.current)
      redirect_to budget_allocations_path(@budget), notice: "Allocation was removed."
    else
      redirect_to budget_allocations_path(@budget), alert: "Allocation was not removed."
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
      params.require(:allocation).permit(:name, :amount, :currency_code, :rate, :icon, :colour)
    end
end
