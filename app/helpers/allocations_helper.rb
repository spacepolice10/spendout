module AllocationsHelper
  def allocation_source_options(sources)
    sources.map do |source|
      available = formatted_amount(source.available_amount, source.currency)
      [ "#{source.name} — #{available} available (#{source.currency_code})", source.id ]
    end
  end
end
