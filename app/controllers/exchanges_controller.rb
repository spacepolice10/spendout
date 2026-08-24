class ExchangesController < ApplicationController
  before_action :set_parent_source

  def new
    @exchange = @parent_source.outgoing_exchanges.new(
      budget: @budget,
      parent_currency_code: @parent_source.currency_code,
      child_source_name: "#{@parent_source.name} exchange"
    )
  end

  def create
    @exchange = @parent_source.outgoing_exchanges.new(exchange_params)
    @exchange.budget = @budget

    if @exchange.save_with_child_source
      redirect_to budget_sources_path(@budget), notice: "Exchange was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_parent_source
      @parent_source = Source.where(budget: Current.user.budgets, deleted_at: nil).find(params[:source_id])
      @budget = @parent_source.budget
    end

    def exchange_params
      params.require(:exchange).permit(:child_source_name, :child_currency_code, :parent_amount, :rate)
    end
end
