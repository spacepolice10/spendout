require "application_system_test_case"

class LandingFeatureChipsTest < ApplicationSystemTestCase
  test "mobile feature chips form an oversized clipped cloud" do
    page.current_window.resize_to(390, 844)
    visit landing_path

    layout = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const frame = document.querySelector('[data-feature-chips]')
        const cloud = frame.querySelector('[data-feature-chip-cloud]')
        const chapter = frame.closest('[data-landing-chapter]')

        return {
          overflowX: getComputedStyle(frame).overflowX,
          overflowY: getComputedStyle(frame).overflowY,
          frameWidth: frame.getBoundingClientRect().width,
          cloudWidth: cloud.getBoundingClientRect().width,
          chapterWidth: chapter.getBoundingClientRect().width
        }
      })()
    JAVASCRIPT

    assert_equal "clip", layout["overflowX"]
    assert_equal "visible", layout["overflowY"]
    assert_operator layout["frameWidth"], :>, layout["chapterWidth"]
    assert_operator layout["cloudWidth"], :>, layout["frameWidth"]
    assert_selector "[data-feature-chip-cloud] a", count: Tour::FEATURES.size, visible: :all
  end
end
