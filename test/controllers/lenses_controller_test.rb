require "test_helper"

class LensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    sign_in_as(@user)
  end

  test "dashboard ensures and renders the built-in money and plan lenses" do
    assert_difference("Lens.count", 2) { get budget_lenses_path(@budget) }

    assert_response :success
    assert_select "[data-testid='source-holder-lens']", count: 1
    assert_select "[data-testid='plan-overview-lens']", count: 1
    assert_select "[data-testid='plan-overview-lens'] time", count: 0
    assert_select "[data-testid='plan-overview-lens'] [data-testid='allocation-compact']", count: 1
    assert_select "[data-testid='plan-overview-lens'] [data-testid='allocation-compact-progress'] span", count: 20
    assert_select "[data-testid='plan-overview-lens'] [data-allocation-envelope]", count: 1
    assert_select "[data-testid='plan-overview-lens'] a[href='#{allocation_path(allocations(:active))}']"
    assert_select "[data-testid='plan-overview-lens'] a[href='#{allocation_path(allocations(:active))}'][role='button']", count: 0
    assert_select "[data-testid='plan-overview-lens'] form", count: 0
    assert_select "[data-lens] form[action*='/lenses/']", count: 0
    assert_select "[data-lens] > footer[data-lens-controls] a[href='#{budget_sources_path(@budget)}']", count: 0
    assert_select "[data-lens] > footer.lens-add-controls[data-lens-controls] a.lens-add-button[href='#{new_budget_source_path(@budget)}'][aria-label='Add wallet']", count: 1 do
      assert_select ".icon-wrap .icon", count: 1
      assert_select "span", text: "Wallet"
    end
    assert_select "[data-lens] > footer.lens-add-controls[data-lens-controls] a.lens-add-button[href='#{new_budget_exchange_path(@budget)}'][aria-label='Add exchange']", count: 1 do
      assert_select ".icon-wrap .icon", count: 1
      assert_select "span", text: "Exchange"
    end
    assert_select "[data-lens] > footer[data-lens-controls] a[href='#{budget_allocations_path(@budget)}']", count: 0
    assert_select "[data-lens] > footer.lens-add-controls[data-lens-controls] a.lens-add-button[href='#{new_budget_allocation_path(@budget)}'][aria-label='Add allocation']", count: 1 do
      assert_select ".icon-wrap .icon", count: 1
      assert_select "span", text: "Allocation"
    end
    assert_select "[data-lens] > header nav", count: 0
    assert_select "[data-lens] > main article > footer", count: 0
    assert_select "a[href='#{new_budget_lens_path(@budget)}']", count: 0
    assert_select "a[href='#{edit_budget_lenses_path(@budget)}']", text: /Configure lenses/, count: 1
    assert_select "nav[aria-label='Add'] > div" do
      assert_select "a[href='#{new_budget_income_path(@budget)}']", text: "Income", count: 1
      assert_select "a[href='#{new_budget_expense_path(@budget)}']", text: "Expense", count: 1
    end
    assert_select "dialog#add-dialog", count: 0
  end

  test "plan lens teaches the user what to do when nothing is planned" do
    @budget.allocations.update_all(deleted_at: Time.current)

    get budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-testid='plan-overview-lens'] [data-testid='plan-overview-tip']" do
      assert_select "h2", text: "Plan important spending first"
      assert_select "p", text: /Set money aside for essentials/
    end
    assert_select "[data-testid='plan-overview-lens'] [data-testid='allocation-compact']", count: 0
  end

  test "source holder teaches the user what to do when there are no sources" do
    @budget.sources.update_all(deleted_at: Time.current)

    get budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-testid='source-holder-lens'] [data-testid='source-holder-tip']" do
      assert_select "h2", text: "Add your wallets or cards"
      assert_select "p", text: /track the money available/
      assert_select "p", text: /cash, a bank account, or a debit or credit card/
    end
    assert_select "[data-testid='source-holder-lens'] .source-holder-total", count: 0
    assert_select "[data-testid='source-holder-lens'] .source-holder-stack", count: 0
  end

  test "source holder shows the available total above the wallet stack" do
    @budget.sources.create!(name: "Cash", amount: 80, currency_code: "USD", colour: "orange", design: :cash)

    get budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-testid='source-holder-lens'] .source-holder-total" do
      assert_select "small", text: "Available total"
      assert_select "strong"
    end
    assert_select "[data-testid='source-holder-stack'][role='region'] .source-holder-card", count: 2
  end

  test "plan lens stamps finished allocations" do
    allocations(:active).update!(finished_at: Time.current)

    get budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-testid='allocation-compact'][data-finished-allocation]" do
      assert_select "mark[data-finished-stamp]", text: "FINISHED", count: 1
    end
  end

  test "lens lab presents every lens and its creation flows" do
    get new_budget_lens_path(@budget)

    assert_response :success
    assert_select "header nav a[href='#{budget_lenses_path(@budget)}'][data-intent='ghost'][data-action*='history#back'][aria-label='Back to dashboard']"
    assert_select "[data-lens-option]", count: 6
    assert_select "[data-lens-option] > header .icon-wrap", count: 0
    assert_select "[data-lens-option] > header h2", count: 6
    assert_select "[data-active-lens]", count: 2
    assert_select "[data-lens-preview]", count: 0
    assert_select "input[name='lens_preview']", count: 0
    assert_select "img.lens-art", count: 0
    assert_select "[data-lens-option='tiny_leaks']", count: 0
    assert_select "[data-lens-option='weekday_fingerprint']", count: 0
    assert_select "[data-lens-option='recent_expenses']", count: 0
    %w[money_weather spree_detector payday_gravity repeat_offenders parallel_you].each do |name|
      assert_select "[data-lens-option='#{name}']", count: 0
    end
    assert_select "form[action='#{budget_rollover_path(@budget)}'][method='post']"
    assert_select "a[href='#{new_budget_rate_info_path(@budget)}']"
  end

  test "lens configuration forms cancel to lenses" do
    [
      new_budget_most_expensive_categories_path(@budget),
      new_budget_rate_info_path(@budget)
    ].each do |path|
      get path

      assert_response :success
      assert_select "a[href='#{budget_lenses_path(@budget)}'][data-action*='history#back']", text: /Cancel/
    end
  end

  test "lens management screen shows active lenses without an add button" do
    rollover_lens = @budget.lenses.create!(lensable: Rollover.new(
      limit_source: :manual,
      amount: 300,
      currency_code: "USD",
      rate: 1,
      starts_on: @budget.period_from,
      ends_on: @budget.period_to
    ))

    get new_budget_lens_path(@budget)

    assert_response :success
    assert_select "[data-lens-option='rollover'][data-active-lens]", count: 1 do
      assert_select "a[aria-label='Add Daily rollover']", count: 0
    end

    get edit_budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-active-lens][data-lens-id='#{rollover_lens.id}']", text: /Daily rollover/
  end

  test "lists active lenses in dashboard order" do
    @budget.ensure_builtin_lenses!
    upcoming = @budget.lenses.create!(lensable: UpcomingRecurrences.new)
    upcoming.move!("up")

    get edit_budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-active-lens]", count: 3
    assert_select "[data-active-lens] > header .icon-wrap", count: 0
    assert_select "[data-active-lens] img.lens-art", count: 0
    assert_select "[data-active-lens]:nth-child(2)[data-lens-id='#{upcoming.id}']"
    assert_select "[data-active-lens][data-lens-id='#{upcoming.id}'] [data-pill-group]", count: 1
    assert_select "form[action='#{move_budget_lens_path(@budget, upcoming)}']", count: 2
    assert_select "form[action='#{budget_lens_path(@budget, upcoming)}'][method='post']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button[aria-label='Remove Upcoming subs'][data-turbo-confirm='Remove Upcoming subs from your dashboard?']"
    end
    Lens::BUILTIN_TYPES.each do |type|
      builtin = @budget.lenses.find_by!(lensable_type: type)
      assert_select "form[action='#{budget_lens_path(@budget, builtin)}']", count: 0
    end
  end

  test "moves an active lens up and reflects the order on the dashboard" do
    @budget.ensure_builtin_lenses!
    upcoming = @budget.lenses.create!(lensable: UpcomingRecurrences.new)

    patch move_budget_lens_path(@budget, upcoming), params: { direction: "up" }

    assert_redirected_to edit_budget_lenses_path(@budget)
    assert_equal [ "SourceHolder", "UpcomingRecurrences", "PlanOverview" ], @budget.lenses.positioned.pluck(:lensable_type)

    get budget_lenses_path(@budget)
    assert_select "[data-mobile-lens-carousel] [data-testid='upcoming-recurrences-lens']", count: 1
    assert_select "[data-mobile-recent-records] [data-testid='recent-records']", count: 1
  end

  test "rejects an invalid lens move direction" do
    @budget.ensure_builtin_lenses!
    lens = @budget.lenses.positioned.first

    patch move_budget_lens_path(@budget, lens), params: { direction: "sideways" }

    assert_response :unprocessable_entity
  end

  test "upcoming subs lens renders a compact calendar for the month ahead" do
    @budget.lenses.create!(lensable: UpcomingRecurrences.new)
    recurrence = @budget.recurrences.create!(
      name: "Netflix",
      category: categories(:active),
      amount: 20,
      currency_code: "USD",
      occurs_on: Date.new(2026, 9, 12),
      occurrence_period_in_days: 30
    )

    travel_to Date.new(2026, 9, 7) do
      get budget_lenses_path(@budget)
    end

    assert_response :success
    assert_select "[data-testid='upcoming-recurrences-lens'] table[data-upcoming-subs-calendar]", count: 1 do
      assert_select "caption", count: 0
      assert_select "th", count: 0
      assert_select "td", count: 35
      assert_select "td[data-today='true'] time[datetime='2026-09-07']", text: /M\s*7/
      assert_select "td[data-today='true'] time abbr[title='Monday']", text: "M"
      assert_select "td[data-weekend='true']", count: 10
      assert_select "td[data-weekend='true'] time[datetime='2026-09-12'] abbr[title='Saturday']", text: "S"
      assert_select "td[data-weekend='false'] time[datetime='2026-09-07']"
    end
    assert_select "[data-testid='upcoming-recurrences-lens'] [data-upcoming-sub]", count: 1 do
      assert_select "strong", count: 0
      assert_select "small", count: 0
      assert_select ".icon-wrap .icon", count: 1
    end
    assert_select "[data-testid='upcoming-recurrences-lens'] a[href='#{recurrence_path(recurrence)}'][aria-label='View Netflix, $20']"
    assert_select "[data-lens] > footer.lens-add-controls[data-lens-controls] a.lens-add-button[href='#{new_budget_recurrence_path(@budget)}'][aria-label='Add subscription']", count: 1 do
      assert_select ".icon-wrap .icon", count: 1
      assert_select "span", text: "Subscription"
    end
  end

  test "most expensive categories lens renders proportional category arcs" do
    @budget.lenses.create!(lensable: MostExpensiveCategories.new(starts_on: @budget.period_from))

    travel_to Date.new(2026, 9, 7) do
      get budget_lenses_path(@budget)
    end

    assert_response :success
    assert_select ".most-expensive-categories[data-testid='most-expensive-categories-lens']" do
      assert_select "svg[role='img'] title", text: I18n.t("lenses.types.most_expensive_categories")
      assert_select "[data-category-arc]", count: 1
      assert_select "[data-category-arc-track]", count: 1
      assert_select "[data-category-arc-border]", count: 1
      assert_select "[data-category-arc-value]", count: 1
      assert_select "ol li[data-category-chip]", count: 1, text: /Housing.*\$125/
    end
  end

  test "rate info lens uses the exchange rate board design" do
    @budget.lenses.create!(lensable: RateInfo.new(currency_codes: [ "EUR" ]))
    CurrencyReference.preserve(
      "reference_date" => "2026-09-07",
      "rates" => { "EUR" => "1", "USD" => "1.2" },
      "reference_dates" => { "EUR" => "2026-09-04", "USD" => "2026-09-07" }
    )

    travel_to Date.new(2026, 9, 7) do
      get budget_lenses_path(@budget)
    end

    assert_response :success
    assert_select ".rate-info[data-testid='rate-info-lens'][data-rate-board]" do
      assert_select "h3", text: "Exchange rates"
      assert_select ".rate-info-list" do
        assert_select "table" do
          assert_select "[data-rate-code]", text: "EUR"
          assert_select "[data-rate-name]", count: 0
          assert_select "[data-rate-display]", text: /0\.8333/
          assert_select ".rate-info-date", count: 0
        end
      end
      assert_select "footer span", count: 0
      assert_select "footer time[datetime='2026-09-07']"
    end
    assert_select "[data-lens] > footer.lens-add-controls[data-lens-controls] a.lens-add-button[href='#{edit_budget_rate_info_path(@budget)}'][aria-label='Choose currencies']"
  ensure
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "renders cybercat only as the permanent dashboard check-in" do
    get budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-testid='cybercat-lens']", count: 0
    assert_select ".cybercat[data-testid='mobile-cybercat-insight'] a.cybercat-face[href='#{user_path}'][aria-label='User']"
    assert_select "[data-lens-menu]", count: 0
    assert_select "[data-lens] form[action*='/lenses/']", count: 0
  end

  test "dashboard renders one permanent insight, a widget carousel, and recent records" do
    get budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-testid='mobile-cybercat-insight'] a[href='#{user_path}'][aria-label='User']"
    assert_select "[data-testid='mobile-cybercat-insight'] p", count: 1
    assert_select "[data-mobile-lens-carousel] [data-testid='cybercat-lens']", count: 0
    assert_select "[data-mobile-lens-carousel] [data-testid='recent-records']", count: 0
    assert_select "[data-mobile-lens-carousel] [data-testid='source-holder-lens']", count: 1
    assert_select "[data-mobile-lens-carousel] [data-testid='plan-overview-lens']", count: 1
    assert_select "[data-mobile-lens-section] > header a[href='#{edit_budget_lenses_path(@budget)}'][role='button']", text: /Configure lenses/
    assert_select "[data-mobile-lens-section] > header h1", count: 0
    assert_select "[data-mobile-recent-records] [data-testid='recent-records']", count: 1
    assert_select "[data-mobile-recent-records] [data-testid='expense-card']", count: 1
    assert_select "[data-mobile-recent-records] > header a[href='#{budget_records_path(@budget)}']", count: 0
    assert_select "[data-mobile-recent-records] form[action*='/lenses/']", count: 0
    assert_select "[data-lens-menu]", count: 0
  end

  test "dashboard recent records include incomes and expenses" do
    @budget.incomes.create!(source: sources(:active), source_name: "Salary", amount: 80,
      currency_code: "USD", occurred_on: Date.new(2026, 8, 20))

    get budget_lenses_path(@budget)

    assert_response :success
    assert_select "[data-mobile-recent-records] [data-testid='expense-card']", count: 1
    assert_select "[data-mobile-recent-records] [data-testid='income-card']", count: 1
    assert_select "[data-mobile-recent-records] [data-testid='income-card'] [data-expense-name]", text: "Salary"
  end

  test "dashboard timeline paginates with an infinite-scroll sentinel" do
    15.times do |index|
      @budget.expenses.create!(source: sources(:active), category: categories(:active), amount: 1,
        occurred_on: @budget.period_from + index.days, note: "Expense #{index}")
    end

    get budget_lenses_path(@budget)

    assert_select "[data-mobile-recent-records] [data-testid='expense-card']", count: 15
    assert_select "turbo-frame#records-pagination-contents-1"
    assert_select "a[data-testid='records-load-more'][data-pagination-target='paginationLink']"
  end

  test "dashboard day headers use the full day's total when a page splits a date" do
    newer_day = @budget.period_from + 1.day
    older_day = @budget.period_from
    10.times do |index|
      @budget.expenses.create!(source: sources(:active), category: categories(:active), amount: 2,
        occurred_on: newer_day, note: "Newer #{index}")
    end
    10.times do |index|
      @budget.expenses.create!(source: sources(:active), category: categories(:active), amount: 3,
        occurred_on: older_day, note: "Older #{index}")
    end

    get budget_lenses_path(@budget)

    assert_select "[data-record-day][data-date='#{older_day.iso8601}'] [data-testid='record-day-total']",
      text: /#{Regexp.escape(ApplicationController.helpers.formatted_amount(30, "USD"))}/
  end

  test "cybercat changes the featured insight during the day" do
    travel_to Time.zone.local(2026, 9, 8, 9) do
      get budget_lenses_path(@budget)

      assert_select "[data-testid='mobile-cybercat-insight'] p", text: /safe for today|comfortable pace|remains available/
    end

    travel_to Time.zone.local(2026, 9, 8, 15) do
      get budget_lenses_path(@budget)

      assert_select "[data-testid='mobile-cybercat-insight'] p", text: /expense today|expenses today|No expenses recorded today/
    end
  end

  test "adds only one rollover gauge" do
    assert_difference([ "Lens.count", "Rollover.count" ], 1) { post budget_rollover_path(@budget) }
    assert_redirected_to budget_lenses_path(@budget)

    rollover = @budget.lenses.find_by!(lensable_type: "Rollover").lensable
    assert rollover.budget?
    assert_equal @budget.sources_amount_in_base, rollover.opening_amount
    assert_equal @budget.base_currency_code, rollover.currency_code
    assert_equal 1, rollover.rate
    assert_equal @budget.period_from, rollover.starts_on
    assert_equal @budget.period_to, rollover.ends_on

    assert_no_difference([ "Lens.count", "Rollover.count" ]) { post budget_rollover_path(@budget) }
    assert_redirected_to budget_lenses_path(@budget)
  end

  test "does not expose another user's dashboard" do
    get budget_lenses_path(budgets(:other))
    assert_response :not_found
  end
end
