module ApplicationHelper
  def formatted_amount(amount, currency)
    number_to_currency(
      amount,
      unit: currency.symbol,
      strip_insignificant_zeros: true
    )
  end

  def colour_styles(colour)
    return unless Colourable::CATALOG.key?(colour)

    "background: var(--color-palette-#{colour}); color: var(--color-invert-1);"
  end

  def icon_tag(icon, options = {})
    icon_name = icon.presence
    tag.span(
      tag.i("", class: "icon", style: "--icon-mask: var(--icon-#{icon_name});", aria: { hidden: true }),
      **options,
      class: class_names("icon-wrap", options[:class]),
      style: options[:style]
    )
  end
end
