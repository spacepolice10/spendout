class AllocationsController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_allocation, only: %i[ show finish reopen destroy ]

  def index
    @allocations = @budget.allocations.includes(:expenses).planned.where(deleted_at: nil).order(:created_at, :id)
  end

  def show
    @expenses = set_page_and_extract_portion_from(
      @allocation.expenses.includes(:source, :allocation)
        .order(occurred_on: :desc, created_at: :desc, id: :desc)
    )
    @expenses_by_date = @expenses.group_by(&:occurred_on)
    @expense_totals_by_date = @expenses_by_date.transform_values do |expenses|
      expenses.sum { |expense| expense.amount_in_base_currency * @allocation.rate }
    end
  end

  def new
    @allocation = @budget.allocations.new(currency_code: @budget.base_currency_code, rate: 1)
  end

  def create
    @allocation = @budget.allocations.new(allocation_params)

    if @allocation.save
      notice = if @budget.overallocated?
        t("allocations.create.overallocated")
      else
        t("allocations.create.success")
      end
      redirect_to budget_allocations_path(@budget), notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def finish
    if @allocation.planned? && @allocation.active? && @allocation.update(finished_at: Time.current)
      redirect_to budget_allocations_path(@budget), notice: t("allocations.finish.success")
    else
      redirect_to budget_allocations_path(@budget), alert: t("allocations.finish.failure")
    end
  end

  def reopen
    if @allocation.planned? && @allocation.finished? && !@allocation.deleted? && !@budget.archived? &&
        @allocation.update(finished_at: nil)
      redirect_to budget_allocations_path(@budget), notice: t("allocations.reopen.success")
    else
      redirect_to allocation_path(@allocation), alert: t("allocations.reopen.failure")
    end
  end

  def destroy
    if @allocation.update(deleted_at: Time.current)
      redirect_to budget_allocations_path(@budget), notice: t("allocations.destroy.success")
    else
      redirect_to budget_allocations_path(@budget), alert: t("allocations.destroy.failure")
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
