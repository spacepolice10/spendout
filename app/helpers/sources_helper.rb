module SourcesHelper
  def colour_styles(colour)
    return unless Colourable::CATALOG.key?(colour)

    "background: var(--color-palette-#{colour}); color: var(--color-invert-1);"
  end
end
