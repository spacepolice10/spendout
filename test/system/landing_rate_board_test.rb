require "application_system_test_case"

class LandingRateBoardTest < ApplicationSystemTestCase
  test "rates settle when the board enters the viewport" do
    visit landing_path

    board = find("[data-rate-board]")
    board.execute_script("this.scrollIntoView({ block: 'center' })")

    assert_selector "[data-rate-board-entering]", wait: 1
    assert_no_selector "[data-rate-board-entering]", wait: 1
    assert_selector "[data-rate-display]", text: "26,300"
    assert_equal "", evaluate_script("document.querySelector('[data-segment-digit=\".\"]').textContent")
  end

  test "sample rates remain static" do
    visit landing_path

    board = find("[data-rate-board]")
    assert_selector "[data-rate-code]", text: "EUR", match: :first
    assert_selector "[data-rate-display]", text: "26,300"

    sleep 0.3
    assert_selector "[data-rate-code]", text: "EUR", match: :first
    assert_selector "[data-rate-display]", text: "26,300"
  end

  test "reduced motion keeps the initial snapshot" do
    page.driver.browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [ { name: "prefers-reduced-motion", value: "reduce" } ]
    )

    visit landing_path
    sleep 0.2

    assert_selector "[data-rate-code]", text: "EUR", match: :first
    assert_selector "[data-rate-display]", text: "26,300"
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
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
