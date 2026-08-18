module BudgetsHelper
  def source_amount(source)
    number_to_currency(
      source.amount,
      unit: source.currency.symbol,
      strip_insignificant_zeros: true
    )
  end
end
