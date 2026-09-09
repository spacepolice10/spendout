class ExchangesController < ApplicationController
  before_action :set_exchange_context

  def new
    @sender_source ||= @sources.first
    @exchange = @budget.exchanges.new(
      sender_source: @sender_source,
      receiver_source_name: "#{@sender_source.name} exchange",
      receiver_currency_code: @sender_source.currency_code,
      rate: 1
    )
  end

  def create
    @sender_source ||= @sources.find_by(id: exchange_params[:sender_source_id])
    @exchange = @budget.exchanges.new(exchange_params.except(:sender_source_id).merge(sender_source: @sender_source))

    if @exchange.save_with_receiver_source
      redirect_to budget_lenses_path(@budget), notice: "Exchange was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_exchange_context
      if params[:source_id]
        @sender_source = Source.where(budget: Current.user.budgets, deleted_at: nil).find(params[:source_id])
        @budget = @sender_source.budget
      else
        @budget = Current.user.budgets.find(params[:budget_id])
      end
      @sources = @budget.sources.where(deleted_at: nil).order(:name)
    end

    def exchange_params
      params.require(:exchange).permit(:sender_source_id, :receiver_source_name, :receiver_currency_code, :sender_amount, :rate)
    end
end
