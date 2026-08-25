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
    "shopping-cart" => "Shopping cart",
    "burger" => "Food",
    "coffee" => "Coffee",
    "bulb" => "Utilities",
    "heartbeat" => "Health",
    "movie" => "Entertainment",
    "school" => "Education",
    "shirt" => "Clothing",
    "barbell" => "Fitness",
    "flower" => "Flowers",
    "diamond" => "Jewellery",
    "paw" => "Pets",
    "sparkles" => "Beauty",
    "baby-carriage" => "Childcare",
    "shield-check" => "Insurance",
    "receipt-dollar" => "Taxes",
    "tools" => "Repairs",
    "bus" => "Public transport",
    "repeat" => "Subscriptions",
    "glass" => "Nightlife",
    "device-laptop" => "Electronics",
    "device-mobile" => "Mobile",
    "spray" => "Household supplies",
    "brand-youtube" => "YouTube",
    "brand-spotify" => "Spotify",
    "brand-netflix" => "Netflix",
    "headphones" => "Music streaming"
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
