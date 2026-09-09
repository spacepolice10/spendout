class MostExpensiveCategoriesController < ApplicationController
  before_action :set_budget

  def new
    @most_expensive_categories = MostExpensiveCategories.new(starts_on: [ Date.current - 7.days, @budget.period_from ].max)
  end

  def create
    @most_expensive_categories = MostExpensiveCategories.new(most_expensive_categories_params)
    @lens = @budget.lenses.build(lensable: @most_expensive_categories)
    if @lens.save
      redirect_to budget_lenses_path(@budget), notice: t("most_expensive_categories.create.success")
    else
      @most_expensive_categories.validate
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def most_expensive_categories_params
      params.require(:most_expensive_categories).permit(:starts_on)
    end
end
