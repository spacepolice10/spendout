class RolloversController < ApplicationController
  before_action :set_budget

  def create
    @rollover = Rollover.new(
      limit_source: :budget,
      amount: 0,
      opening_amount: @budget.sources_amount_in_base,
      currency_code: @budget.base_currency_code,
      rate: 1,
      starts_on: @budget.period_from,
      ends_on: @budget.period_to
    )
    @lens = @budget.lenses.build(lensable: @rollover)

    if @lens.save
      redirect_to budget_lenses_path(@budget), notice: t("rollovers.create.success")
    else
      redirect_to budget_lenses_path(@budget), alert: t("rollovers.create.failure")
    end
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end
end
