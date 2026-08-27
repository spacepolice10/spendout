class CurrencyReferencesController < ApplicationController
  def show
    base = params.fetch(:base, "USD").to_s.upcase
    rate_catalog = CurrencyReference.rates_against(base)

    render json: { base:, rate_catalog: }
  end
end
