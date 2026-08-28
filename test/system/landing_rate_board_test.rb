require "application_system_test_case"

class LandingRateBoardTest < ApplicationSystemTestCase
  test "renders static sample rates" do
    visit landing_path

    assert_selector "[data-rate-code]", text: "EUR", match: :first
    assert_selector "[data-rate-display]", text: "26,300"
    assert_no_selector "[data-rate-board][data-controller]"
  end

  test "mobile layout keeps the board and copy in the document flow" do
    page.current_window.resize_to(320, 800)
    visit landing_path

    board_position = evaluate_script("getComputedStyle(document.querySelector('[data-rate-board]')).position")
    copy_position = evaluate_script("getComputedStyle(document.querySelector('[data-currency-story] [data-rate-copy]')).position")

    assert_equal "relative", board_position
    assert_equal "static", copy_position
    assert_selector "[data-rate-board] table", visible: true
  end
end
