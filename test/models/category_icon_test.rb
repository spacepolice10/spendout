require "test_helper"

class CategoryIconTest < ActiveSupport::TestCase
  test "matches exact, spaced, and joined category names" do
    assert_equal "burger", CategoryIcon.match("Fast Food")
    assert_equal "burger", CategoryIcon.match("fastfood")
    assert_equal "shopping-cart", CategoryIcon.match("Weekly groceries")
    assert_equal "heartbeat", CategoryIcon.match("Health care")
    assert_equal "flower", CategoryIcon.match("Flowers")
    assert_equal "diamond", CategoryIcon.match("Jewellery")
  end

  test "matches a single-character typo conservatively" do
    assert_equal "shopping-cart", CategoryIcon.match("groceris")
    assert_equal "coffee", CategoryIcon.match("cofee")
  end

  test "matches common household and recurring spending" do
    assert_equal "paw", CategoryIcon.match("Vet")
    assert_equal "sparkles", CategoryIcon.match("Haircut")
    assert_equal "baby-carriage", CategoryIcon.match("Daycare")
    assert_equal "shield-check", CategoryIcon.match("Insurance premium")
    assert_equal "receipt-dollar", CategoryIcon.match("Income tax")
    assert_equal "tools", CategoryIcon.match("Home repairs")
    assert_equal "bus", CategoryIcon.match("Public transport")
    assert_equal "repeat", CategoryIcon.match("Subscriptions")
    assert_equal "glass", CategoryIcon.match("Nightlife")
    assert_equal "device-laptop", CategoryIcon.match("Electronics")
    assert_equal "device-mobile", CategoryIcon.match("Mobile phone plan")
    assert_equal "spray", CategoryIcon.match("Cleaning supplies")
  end

  test "falls back for unknown and short category names" do
    assert_equal "wallet", CategoryIcon.match("Miscellaneous thing")
    assert_equal "wallet", CategoryIcon.match("cab")
    assert_equal "wallet", CategoryIcon.match(nil)
  end

  test "only returns icons supported by allocations" do
    CategoryIcon::KEYWORDS.each_key do |icon|
      assert_includes Allocation.icon_catalog, icon
    end
  end

  test "assigns a supported colour to every matched category" do
    assert_equal "orange", CategoryIcon.colour("Burger")
    assert_equal "yellow", CategoryIcon.colour("Car")
    assert_equal "red", CategoryIcon.colour("Workout")
    assert_equal "pink", CategoryIcon.colour("Flowers")
    assert_equal "cyan", CategoryIcon.colour("Jewellery")
    assert_equal Colourable::DEFAULT_COLOUR, CategoryIcon.colour("Unknown")

    CategoryIcon::COLOURS.each_value do |colour|
      assert_includes Allocation.colour_catalog, colour
    end
  end

  test "recognizes popular media services" do
    assert_equal "brand-youtube", CategoryIcon.match("YouTube Premium")
    assert_equal "brand-spotify", CategoryIcon.match("Spotify")
    assert_equal "brand-netflix", CategoryIcon.match("Netflix")
    assert_equal "headphones", CategoryIcon.match("Apple Music")
    assert_equal "movie", CategoryIcon.match("Disney Plus")
    assert_equal "movie", CategoryIcon.match("HBO Max")

    assert_equal "red", CategoryIcon.colour("YouTube")
    assert_equal "lime", CategoryIcon.colour("Spotify")
    assert_equal "red", CategoryIcon.colour("Netflix")
  end
end
