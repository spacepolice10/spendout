class CategoriesController < ApplicationController
  before_action :set_budget
  before_action :set_category, only: %i[ show update destroy ]

  def index
    @categories = @budget.categories.includes(:allocation).order(:deleted_at, :name)
  end

  def show; end

  def update
    if @category.update(category_params)
      redirect_to budget_category_path(@budget, @category), notice: t("categories.update.success")
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @category.retire!
    redirect_to budget_categories_path(@budget), notice: t("categories.destroy.success")
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def set_category
      @category = @budget.categories.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :icon, :colour)
    end
end
