# frozen_string_literal: true

module Colourable
  extend ActiveSupport::Concern

  DEFAULT_COLOUR = "green"
  CATALOG = {
    "green" => "Green",
    "red" => "Red",
    "blue" => "Blue",
    "yellow" => "Yellow",
    "violet" => "Violet"
  }.freeze

  included do
    attribute :colour, :string, default: DEFAULT_COLOUR

    validates :colour, inclusion: { in: CATALOG.keys }
  end

  class_methods do
    def colour_catalog
      Colourable::CATALOG
    end

    def colour_options
      colour_catalog.map { |value, label| [ label, value ] }
    end
  end
end
