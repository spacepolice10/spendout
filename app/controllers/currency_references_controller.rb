class CurrencyReferencesController < ApplicationController
  def show
    base = params.fetch(:base, "USD").to_s.upcase
    rates = CurrencyReference.rates_against(base)

    render json: { base:, rates: }
  end
end
