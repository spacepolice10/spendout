class UpcomingRecurrencesController < ApplicationController
  def create
    budget = Current.user.budgets.find(params[:budget_id])
    lens = budget.lenses.build(lensable: UpcomingRecurrences.new)
    if lens.save
      redirect_to budget_lenses_path(budget), notice: t("upcoming_recurrences.create.success")
    else
      redirect_to budget_lenses_path(budget), alert: t("upcoming_recurrences.create.failure")
    end
  end
end
