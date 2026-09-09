module ApplicationHelper
  def mobile_variant?
    request.variant.include?(:mobile)
  end

  def current_user
    Current.user
  end

  def formatted_amount(amount, currency_code)
    number_to_currency(
      amount,
      unit: Currency.find!(currency_code)[:symbol],
      strip_insignificant_zeros: true
    )
  end

  def compact_formatted_amount(amount, currency_code)
    return formatted_amount(amount, currency_code) if amount.abs < 1_000

    compact_number = number_to_human(
      amount,
      format: "%n%u",
      precision: 3,
      significant: true,
      units: { thousand: "K", million: "M", billion: "B", trillion: "T" }
    )
    "#{Currency.find!(currency_code)[:symbol]}#{compact_number}"
  end

  def formatted_rate(rate)
    precision = rate < 10 ? 4 : rate < 1_000 ? 2 : 0
    number_with_precision(rate, precision:, delimiter: ",")
  end

  def colour_styles(colour)
    return unless Colourable::CATALOG.key?(colour)

    "border-color: var(--color-palette-#{colour}); color: var(--color-palette-#{colour});"
  end

  def icon_colour_styles(colour)
    return unless Colourable::CATALOG.key?(colour)

    "color: var(--color-palette-#{colour});"
  end

  def icon(name, options = {})
    icon_name = name.presence
    tag.span(
      tag.i("", class: "icon", style: "--icon-mask: var(--icon-#{icon_name});", aria: { hidden: true }),
      **options,
      class: class_names("icon-wrap", options[:class]),
      style: options[:style]
    )
  end

  def currency_flag(currency_code, **options)
    country_code = Currency.find!(currency_code)[:country_code]
    data = options.delete(:data).to_h.merge(country_code: country_code)
    image_tag(
      "currency-flags/#{country_code.downcase}.png",
      alt: "",
      width: 32,
      height: 24,
      data: data,
      **options,
      class: class_names("currency-flag", options[:class])
    )
  end

  def feature_path(feature)
    case feature.feature_type
    when "new_expense" then new_budget_expense_path(feature.budget)
    when "new_income" then new_budget_income_path(feature.budget)
    when "new_source" then new_budget_source_path(feature.budget)
    when "new_allocation" then new_budget_allocation_path(feature.budget)
    when "lens_laboratory" then new_budget_lens_path(feature.budget)
    end
  end

  def feature_icon(feature)
    {
      "new_expense" => "receipt-dollar",
      "new_income" => "plus",
      "new_source" => "wallet",
      "new_allocation" => "category",
      "lens_laboratory" => "bulb"
    }.fetch(feature.feature_type)
  end
end
