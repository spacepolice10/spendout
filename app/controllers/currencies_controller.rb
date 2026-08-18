class CurrenciesController < ApplicationController
  before_action :set_budget, only: %i[ index new create ]
  before_action :set_currency, only: %i[ edit update ]
  before_action :ensure_foreign_currency, only: %i[ edit update ]

  def index
    @currencies = [ @budget.base_currency ] +
      @budget.currencies.where.not(id: @budget.base_currency.id).order(:alphabetic_code).to_a
  end

  def new
    @currency_options = available_currency_options
    @currency = @budget.currencies.new(alphabetic_code: @currency_options.first&.last)
  end

  def create
    @currency = @budget.currencies.new(currency_params)

    if @currency.save
      redirect_to budget_currencies_path(@budget), notice: "Currency was added."
    else
      @currency_options = available_currency_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @currency.update(currency_params.slice(:rate))
      redirect_to budget_currencies_path(@budget), notice: "Currency rate was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_budget
      @budget = Current.user.budgets.find(params[:budget_id])
    end

    def set_currency
      @currency = Currency.where(budget: Current.user.budgets).find(params[:id])
      @budget = @currency.budget
    end

    def ensure_foreign_currency
      raise ActiveRecord::RecordNotFound if @currency.base?
    end

    def available_currency_options
      existing_codes = @budget.currencies.pluck(:alphabetic_code)
      Currency.options.reject { |_, code| existing_codes.include?(code) }
    end

    def currency_params
      params.require(:currency).permit(:alphabetic_code, :rate)
    end
end
