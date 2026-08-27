class ExchangesController < ApplicationController
  before_action :set_sender_source

  def new
    @exchange = @sender_source.outgoing_exchanges.new(
      budget: @budget,
      receiver_source_name: "#{@sender_source.name} exchange"
    )
  end

  def create
    @exchange = @sender_source.outgoing_exchanges.new(exchange_params)
    @exchange.budget = @budget

    if @exchange.save_with_receiver_source
      redirect_to budget_sources_path(@budget), notice: "Exchange was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_sender_source
      @sender_source = Source.where(budget: Current.user.budgets, deleted_at: nil).find(params[:source_id])
      @budget = @sender_source.budget
    end

    def exchange_params
      params.require(:exchange).permit(:receiver_source_name, :receiver_currency_code, :sender_amount, :rate)
    end
end
