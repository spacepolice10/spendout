class ReportsController < ApplicationController
  def show
    @budget = Current.user.budgets.find(params[:budget_id])
    @report = @budget.report
  end
end
