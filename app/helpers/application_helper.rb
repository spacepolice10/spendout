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

  def cybercat_spending_answer(percentage, no_expenses: false)
    return "Nothing spent yet—nice." if no_expenses

    case percentage.to_d
    when ..0
      "That’s enough spending for today."
    when ...25
      "You can, but tomorrow will be tighter."
    when ...50
      "Better save some for tomorrow."
    when ...80
      "Yep, still good to go."
    else
      "You’re ahead today—nice."
    end
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
end
