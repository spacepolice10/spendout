class FeaturesController < ApplicationController
  before_action :set_budget

  def favorite
    feature = @budget.features.where(feature_type: Feature::FAVORITABLE_TYPES).find(params[:id])
    feature.update!(favorite: !feature.favorite?)
    redirect_back fallback_location: root_path
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end
end
