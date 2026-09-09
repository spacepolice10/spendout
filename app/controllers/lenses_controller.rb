class LensesController < ApplicationController
  include RecordTimeline

  before_action :set_budget
  before_action :set_lens, only: :move
  before_action :set_removable_lens, only: :destroy

  def index
    @budget.ensure_builtin_lenses!
    @lens_facade = LensFacade.new(@budget)
    @lenses = @lens_facade.ordered.includes(:lensable)
    @snapshots_by_lens_id = @lenses.to_h { |lens| [ lens.id, lens.snapshot ] }

    @mobile_widget_lenses = @lenses
    @mobile_cybercat_snapshot = Cybercat.new.snapshot(budget: @budget)
    load_record_timeline
  end

  def new
    prepare_lens_management
  end

  def edit
    prepare_lens_management
    render :new
  end

  def move
    @lens.move!(params.require(:direction))
    redirect_to edit_budget_lenses_path(@budget), notice: t("lenses.move.success")
  rescue KeyError
    head :unprocessable_entity
  end

  def destroy
    @lens.destroy!
    redirect_to budget_lenses_path(@budget), notice: t("lenses.destroy.success")
  end

  private
    def prepare_lens_management
      @budget.ensure_builtin_lenses!
      @lens_facade = LensFacade.new(@budget)
      @lenses = @lens_facade.ordered
    end

    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def set_lens
      @lens = @budget.lenses.find(params[:id])
    end

    def set_removable_lens
      @lens = @budget.lenses.where.not(lensable_type: Lens::BUILTIN_TYPES).find(params[:id])
    end
end
