class AllocationsController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_allocation, only: :show
  before_action :set_active_sources, only: %i[ new create ]

  def index
    @allocations = @budget.allocations.where(deleted_at: nil).order(:created_at, :id)
  end

  def show
  end

  def new
    @allocation = @budget.allocations.new(amount: 0, source: @budget.base_source)
  end

  def create
    @allocation = @budget.allocations.new(allocation_params.except(:source_id))
    @allocation.source = @active_sources.find_by(id: allocation_params[:source_id])

    if @allocation.save_with_source_capacity
      redirect_to @allocation, notice: "Allocation was created."
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

    def set_active_sources
      @active_sources = @budget.sources.where(deleted_at: nil).order(:created_at, :id)
    end

    def allocation_params
      params.require(:allocation).permit(:name, :amount, :source_id, :icon, :colour)
    end
end
