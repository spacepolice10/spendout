require "test_helper"

class CategoryIconTest < ActiveSupport::TestCase
  test "matches exact, spaced, and joined category names" do
    assert_equal "burger", CategoryIcon.matched_name("Fast Food")
    assert_equal "burger", CategoryIcon.matched_name("fastfood")
    assert_equal "shopping-cart", CategoryIcon.matched_name("Weekly groceries")
    assert_equal "heartbeat", CategoryIcon.matched_name("Health care")
    assert_equal "flower", CategoryIcon.matched_name("Flowers")
    assert_equal "diamond", CategoryIcon.matched_name("Jewellery")
  end

  test "matches a single-character typo conservatively" do
    assert_equal "shopping-cart", CategoryIcon.matched_name("groceris")
    assert_equal "coffee", CategoryIcon.matched_name("cofee")
  end

  test "matches common household and recurring spending" do
    assert_equal "paw", CategoryIcon.matched_name("Vet")
    assert_equal "sparkles", CategoryIcon.matched_name("Haircut")
    assert_equal "baby-carriage", CategoryIcon.matched_name("Daycare")
    assert_equal "shield-check", CategoryIcon.matched_name("Insurance premium")
    assert_equal "receipt-dollar", CategoryIcon.matched_name("Income tax")
    assert_equal "tools", CategoryIcon.matched_name("Home repairs")
    assert_equal "bus", CategoryIcon.matched_name("Public transport")
    assert_equal "repeat", CategoryIcon.matched_name("Subscriptions")
    assert_equal "glass", CategoryIcon.matched_name("Nightlife")
    assert_equal "device-laptop", CategoryIcon.matched_name("Electronics")
    assert_equal "device-mobile", CategoryIcon.matched_name("Mobile phone plan")
    assert_equal "spray", CategoryIcon.matched_name("Cleaning supplies")
  end

  test "falls back for unknown and short category names" do
    assert_equal "wallet", CategoryIcon.matched_name("Miscellaneous thing")
    assert_equal "wallet", CategoryIcon.matched_name("cab")
    assert_equal "wallet", CategoryIcon.matched_name(nil)
  end

  test "only returns icons supported by allocations" do
    CategoryIcon::KEYWORDS.each_key do |icon|
      assert_includes Allocation.icon_catalog, icon
    end
  end

  test "assigns a supported colour to every matched category" do
    assert_equal "orange", CategoryIcon.matched_colour("Burger")
    assert_equal "yellow", CategoryIcon.matched_colour("Car")
    assert_equal "red", CategoryIcon.matched_colour("Workout")
    assert_equal "pink", CategoryIcon.matched_colour("Flowers")
    assert_equal "cyan", CategoryIcon.matched_colour("Jewellery")
    assert_equal Colourable::DEFAULT_COLOUR, CategoryIcon.matched_colour("Unknown")

    CategoryIcon::COLOURS.each_value do |colour|
      assert_includes Allocation.colour_catalog, colour
    end
  end

  test "recognizes popular media services" do
    assert_equal "brand-youtube", CategoryIcon.matched_name("YouTube Premium")
    assert_equal "brand-spotify", CategoryIcon.matched_name("Spotify")
    assert_equal "brand-netflix", CategoryIcon.matched_name("Netflix")
    assert_equal "headphones", CategoryIcon.matched_name("Apple Music")
    assert_equal "movie", CategoryIcon.matched_name("Disney Plus")
    assert_equal "movie", CategoryIcon.matched_name("HBO Max")

    assert_equal "red", CategoryIcon.matched_colour("YouTube")
    assert_equal "lime", CategoryIcon.matched_colour("Spotify")
    assert_equal "red", CategoryIcon.matched_colour("Netflix")
  end

  test "recognizes guitar and instrument spending" do
    assert_equal "guitar-pick", CategoryIcon.matched_name("Electric guitar")
    assert_equal "guitar-pick", CategoryIcon.matched_name("Musical instruments")
    assert_equal "guitar-pick", CategoryIcon.matched_name("Gutar strings")
    assert_equal "orange", CategoryIcon.matched_colour("Guitar lessons")
  end
end
