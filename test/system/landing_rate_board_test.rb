require "application_system_test_case"

class LandingRateBoardTest < ApplicationSystemTestCase
  test "daily gauge and exchange board share the same desktop frame height" do
    page.current_window.resize_to(1200, 900)
    visit landing_path

    frame_heights = evaluate_script(<<~JAVASCRIPT)
      Array.from(document.querySelectorAll('[data-landing-demo-frame]'), (frame) => frame.getBoundingClientRect().height)
    JAVASCRIPT

    assert_equal 2, frame_heights.size
    assert_equal frame_heights.first, frame_heights.last
  end

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
    frame_minimum_heights = evaluate_script(<<~JAVASCRIPT)
      Array.from(document.querySelectorAll('[data-landing-demo-frame]'), (frame) => getComputedStyle(frame).minHeight)
    JAVASCRIPT

    assert_equal "relative", board_position
    assert_equal "static", copy_position
    assert_equal [ "288px", "288px" ], frame_minimum_heights
    assert_selector "[data-rate-board] table", visible: true
  end
end
