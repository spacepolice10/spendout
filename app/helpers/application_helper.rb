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

  def colour_styles(colour)
    return unless Colourable::CATALOG.key?(colour)

    "border-color: var(--color-palette-#{colour}); color: var(--color-palette-#{colour});"
  end

  def icon_colour_styles(colour)
    return unless Colourable::CATALOG.key?(colour)

    "color: var(--color-palette-#{colour});"
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
