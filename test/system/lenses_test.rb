require "application_system_test_case"

class LensesTest < ApplicationSystemTestCase
  setup { sign_in_as users(:one) }

  test "lens lab lists instruments without previews" do
    visit new_budget_lens_path(budgets(:active))

    assert_selector "[data-lens-option]", count: 6
    assert_no_selector "[data-lens-preview]"
    within "[data-lens-option='most_expensive_categories']" do
      assert_text "Top categories"
      assert_text "Ranks spending categories."
    end
  end

  test "dashboard renders permanent money and plan instruments" do
    visit budget_lenses_path(budgets(:active))

    assert_selector "[data-testid='source-holder-lens']"
    assert_selector "[data-testid='plan-overview-lens']"
    assert_selector "[data-testid='recent-records']"
    assert_no_link "Add a lens"
    assert_link "Configure lenses", href: edit_budget_lenses_path(budgets(:active))
    assert_no_selector "[data-mobile-recent-records] a[href='#{budget_records_path(budgets(:active))}']"
  end

  test "source holder shows wallet and exchange actions" do
    budget = budgets(:active)
    visit budget_lenses_path(budget)

    within find("[data-testid='source-holder-lens']").ancestor("[data-lens]") do
      assert_link "Wallet", href: new_budget_source_path(budget)
      assert_link "Exchange", href: new_budget_exchange_path(budget)
      assert_no_link "Transfer"
    end
  end

  test "source holder keeps the total fixed while the compact wallet list scrolls" do
    budget = budgets(:active)
    10.times do |index|
      budget.sources.create!(name: "Wallet #{index}", amount: 25, currency_code: "USD")
    end

    visit budget_lenses_path(budget)
    stack = find("[data-testid='source-holder-stack']")
    scroll_height, client_height = page.evaluate_script(<<~JS)
      (function() {
        var stack = document.querySelector("[data-testid='source-holder-stack']")
        return [stack.scrollHeight, stack.clientHeight]
      })()
    JS

    assert_operator scroll_height, :>, client_height
    assert source_holder_card_in_view?("Main source")
    assert_not source_holder_card_in_view?("Wallet 9")

    stack.scroll_to :bottom

    assert source_holder_card_in_view?("Wallet 9")
    assert_not source_holder_card_in_view?("Main source")
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  test "cybercat face opens the user page" do
    visit budget_lenses_path(budgets(:active))
    find("[data-testid='mobile-cybercat-insight'] a[href='#{user_path}']").click

    assert_current_path user_path
    assert_selector "h1", text: "User"

    find("a[aria-label='Back to dashboard']").click

    assert_current_path budget_lenses_path(budgets(:active))
  end

  test "lens lab back button returns to the dashboard" do
    visit budget_lenses_path(budgets(:active))
    visit new_budget_lens_path(budgets(:active))

    find("a[aria-label='Back to dashboard']").click

    assert_current_path budget_lenses_path(budgets(:active))
  end

  test "rate info setup watches up to four currencies on the board" do
    today = Date.current
    CurrencyReference.preserve(
      "reference_date" => today.iso8601,
      "rates" => { "EUR" => "1", "USD" => "1.2", "CAD" => "1.3" },
      "reference_dates" => { "EUR" => today.iso8601, "USD" => today.iso8601, "CAD" => today.iso8601 }
    )

    visit new_budget_lens_path(budgets(:active))
    within "[data-lens-option='rate_info']" do
      find("a[aria-label='Add Rate info']").click
    end

    assert_selector "h1", text: "Exchange rates"
    choose_rate_info_currency(0, "canadian", "CAD Canadian Dollar")
    click_button "Confirm"

    assert_selector "[data-testid='rate-info-lens'] [data-rate-code]", text: "CAD"
    assert_no_selector "[data-testid='rate-info-lens'] [data-rate-name]"
    find("a[href='#{edit_budget_rate_info_path(budgets(:active))}']").click
    choose_rate_info_currency(1, "euro", "EUR Euro")
    click_button "Confirm"

    assert_selector "[data-testid='rate-info-lens'] [data-rate-code]", text: "CAD"
    assert_selector "[data-testid='rate-info-lens'] [data-rate-code]", text: "EUR"
  ensure
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "rate info list does not trap the lens carousel" do
    today = Date.current
    CurrencyReference.preserve(
      "reference_date" => today.iso8601,
      "rates" => { "EUR" => "1", "USD" => "1.2" },
      "reference_dates" => { "EUR" => today.iso8601, "USD" => today.iso8601 }
    )
    budgets(:active).lenses.create!(lensable: RateInfo.new(currency_codes: [ "EUR" ]))

    visit budget_lenses_path(budgets(:active))
    list = find("[data-testid='rate-info-lens'] .rate-info-list")

    overflow_x, overflow_y, carousel_overflow = page.evaluate_script(<<~JS)
      (function() {
        var list = document.querySelector(".rate-info-list")
        var carousel = document.querySelector("[data-mobile-lens-carousel]")
        var listStyle = getComputedStyle(list)
        return [listStyle.overflowX, listStyle.overflowY, getComputedStyle(carousel).overflowX]
      })()
    JS

    assert_not_includes [ "auto", "scroll" ], overflow_x
    assert_not_includes [ "auto", "scroll" ], overflow_y
    assert_equal "auto", carousel_overflow
    assert_operator list.native.size.height, :>, 0
  ensure
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "lens carousel keeps its scroll position after browser back" do
    budget = setup_scrollable_carousel
    visit budget_lenses_path(budget)
    scrolled = scroll_lens_carousel

    assert_operator scrolled, :>, 0
    click_link "Configure lenses"
    assert_current_path edit_budget_lenses_path(budget)

    page.go_back
    assert_current_path budget_lenses_path(budget)

    assert_in_delta scrolled, lens_carousel_scroll_left, 2
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  test "lens carousel restores scroll from session storage on a fresh visit" do
    budget = setup_scrollable_carousel
    visit budget_lenses_path(budget)
    scrolled = scroll_lens_carousel

    assert_operator scrolled, :>, 0
    visit new_budget_expense_path(budget)
    visit budget_lenses_path(budget)

    assert_in_delta scrolled, lens_carousel_scroll_left, 2
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  test "form cancel returns through browser history" do
    budget = budgets(:active)
    visit budget_lenses_path(budget)
    click_link "Configure lenses"
    within "[data-lens-option='rate_info']" do
      find("a[aria-label='Add Rate info']").click
    end

    assert_current_path new_budget_rate_info_path(budget)
    click_link "Cancel"

    assert_current_path edit_budget_lenses_path(budget)
  end

  test "form cancel keeps the lens carousel scroll position" do
    budget = setup_scrollable_carousel
    visit budget_lenses_path(budget)
    scrolled = scroll_lens_carousel

    assert_operator scrolled, :>, 0
    click_on "Expense"
    assert_current_path new_budget_expense_path(budget)
    click_link "Cancel"

    assert_current_path budget_lenses_path(budget)
    assert_in_delta scrolled, lens_carousel_scroll_left, 2
  ensure
    page.current_window.resize_to(1400, 1400)
  end

  private
    def setup_scrollable_carousel
      page.current_window.resize_to(390, 844)
      budget = budgets(:active)
      budget.ensure_builtin_lenses!
      budget.lenses.create!(lensable: UpcomingRecurrences.new)
      budget.lenses.create!(lensable: MostExpensiveCategories.new(starts_on: budget.period_from))
      budget
    end

    def scroll_lens_carousel
      page.evaluate_async_script(<<~JS)
        var done = arguments[0]
        var carousel = document.querySelector("[data-mobile-lens-carousel]")
        requestAnimationFrame(function() {
          requestAnimationFrame(function() {
            carousel.children[2].scrollIntoView({ inline: "start", block: "nearest" })
            done(carousel.scrollLeft)
          })
        })
      JS
    end

    def lens_carousel_scroll_left
      find("[data-mobile-lens-carousel]")
      page.evaluate_script("document.querySelector('[data-mobile-lens-carousel]').scrollLeft")
    end

    def choose_rate_info_currency(slot, query, label)
      picker = all(".currency-picker")[slot]
      within picker do
        find("button[data-currency-picker-target='currencyTrigger']").click
        find("input[data-currency-picker-target='filter']").set(query)
        find("label[data-currency-picker-target='option']:not([hidden])", text: label).click
      end
    end

    def source_holder_card_in_view?(text)
      page.evaluate_script(<<~JS)
        (function() {
          var stack = document.querySelector("[data-testid='source-holder-stack']")
          var card = Array.prototype.find.call(stack.querySelectorAll(".source-holder-card"), function(node) {
            return node.textContent.indexOf(#{text.to_json}) !== -1
          })
          if (!card) return false
          var stackRect = stack.getBoundingClientRect()
          var cardRect = card.getBoundingClientRect()
          return cardRect.bottom > stackRect.top + 8 && cardRect.top < stackRect.bottom - 8
        })()
      JS
    end
end
