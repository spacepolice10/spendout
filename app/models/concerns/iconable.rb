# frozen_string_literal: true

module Iconable
  extend ActiveSupport::Concern

  DEFAULT_ICON = "wallet"
  CATALOG = {
    "wallet" => "Wallet",
    "building-bank" => "Bank",
    "cash-banknote" => "Cash",
    "credit-card" => "Credit card",
    "coin" => "Coin",
    "pig-money" => "Piggy bank",
    "briefcase" => "Briefcase",
    "home" => "Home",
    "car" => "Car",
    "plane" => "Plane",
    "gift" => "Gift",
    "shopping-cart" => "Shopping cart"
  }.freeze

  included do
    attribute :icon, :string, default: DEFAULT_ICON

    validates :icon, inclusion: { in: CATALOG.keys }
  end

  class_methods do
    def icon_catalog
      Iconable::CATALOG
    end

    def icon_options
      icon_catalog.map { |value, label| [ label, value ] }
    end
  end
end
