require "application_system_test_case"

class RecordsTest < ApplicationSystemTestCase
  setup { sign_in_as users(:one) }

  test "scrolling the dashboard timeline loads the next page of records" do
    budget = budgets(:active)
    20.times do |index|
      budget.expenses.create!(source: sources(:active), category: categories(:active), amount: 1,
        occurred_on: budget.period_from + (index % 10).days, note: "Expense #{index}")
    end

    visit budget_lenses_path(budget)

    assert_selector "[data-testid='expense-card']", count: 15
    assert_selector "[data-testid='records-load-more']", visible: :all
    assert_no_selector "[data-mobile-recent-records] a[href='#{budget_records_path(budget)}']"

    page.execute_script(<<~JS)
      document.querySelector("[data-testid='records-load-more']")?.scrollIntoView({ block: "end" })
    JS

    assert_selector "[data-testid='expense-card']", minimum: 16
    assert_selector "turbo-frame#records-pagination-contents-2", visible: :all

    dates = all("[data-record-day]").map { |day| day["data-date"] }
    assert_equal dates.uniq, dates
  end

  test "dashboard timeline last record sits above the add buttons" do
    budget = budgets(:active)
    8.times do |index|
      budget.expenses.create!(source: sources(:active), category: categories(:active), amount: 1,
        occurred_on: budget.period_from + index.days, note: "Expense #{index}")
    end

    visit budget_lenses_path(budget)
    page.current_window.resize_to(390, 844)
    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

    last_bottom, add_top = page.evaluate_script(<<~JS)
      (function() {
        var cards = document.querySelectorAll("[data-testid='expense-card'], [data-testid='income-card']")
        var last = cards[cards.length - 1]
        var nav = document.querySelector('nav[aria-label="Add"]')
        return [Math.round(last.getBoundingClientRect().bottom), Math.round(nav.getBoundingClientRect().top)]
      })()
    JS

    assert_operator last_bottom, :<=, add_top
  ensure
    page.current_window.resize_to(1400, 1400)
  end
end
