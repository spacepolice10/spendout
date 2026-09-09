class RateInfosController < ApplicationController
  before_action :set_budget

  def new
    existing = @budget.lenses.find_by(lensable_type: "RateInfo")
    return redirect_to edit_budget_rate_info_path(@budget) if existing

    @rate_info = RateInfo.new(currency_codes: default_currency_codes)
  end

  def create
    @rate_info = RateInfo.new(rate_info_params)
    @rate_info.monitored_against = @budget.base_currency_code
    @lens = @budget.lenses.build(lensable: @rate_info)

    if @rate_info.valid? && @lens.save
      redirect_to budget_lenses_path(@budget), notice: t("rate_infos.create.success")
    else
      @rate_info.validate
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @rate_info = rate_info_record
  end

  def update
    @rate_info = rate_info_record
    if @rate_info.update(rate_info_params)
      redirect_to budget_lenses_path(@budget), notice: t("rate_infos.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def rate_info_record
      @budget.lenses.find_by!(lensable_type: "RateInfo").lensable
    end

    def rate_info_params
      params.require(:rate_info).permit(currency_codes: [])
    end

    def default_currency_codes
      codes = @budget.sources.where(deleted_at: nil).distinct.pluck(:currency_code) - [ @budget.base_currency_code ]
      (codes.presence || (%w[ USD EUR GBP ] - [ @budget.base_currency_code ])).first(RateInfo::CAPACITY)
    end
end
