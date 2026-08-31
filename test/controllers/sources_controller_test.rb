require "test_helper"

class SourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @source = sources(:active)
  end

  test "requires authentication" do
    get budget_sources_path(@budget)

    assert_redirected_to new_session_path
  end

  test "index lists sources for the selected budget" do
    sign_in_as(@user)

    get budget_sources_path(@budget)

    assert_response :success
    assert_select "body > main[data-anchor='footer']"
    assert_select "body > footer[data-budget-action]" do
      assert_select "a[href='#{new_budget_source_path(@budget)}']", text: /Add source/
    end
    assert_select "body > main > article > footer", count: 0
    assert_select "[data-testid='source-card']", count: 1
    assert_select "[data-testid='source-card']", text: /Main source/
    assert_select "[data-source-card][style*='--source-colour: var(--color-palette-green)']"
    assert_select "header", text: /Actual remainder:.*\$1,200\.25/m
    assert_select "a[href='#{source_path(@source)}']", text: /Details/
    assert_select "[data-source-card] button[aria-label='Remove source']", count: 0
  end

  test "index paginates exchange history" do
    sign_in_as(@user)
    16.times do |index|
      exchange = @source.outgoing_exchanges.new(
        budget: @budget,
        receiver_source_name: "Euro cash #{index}",
        receiver_currency_code: "EUR",
        sender_amount: 1,
        rate: 1
      )
      assert exchange.save_with_receiver_source
    end

    get budget_sources_path(@budget)

    assert_select "[data-testid='exchange-history-item']", count: 15
    assert_select "nav[aria-label='Pagination for exchanges']", text: /Page 1 of 2/
    assert_select "nav[aria-label='Pagination for exchanges'] a", text: "Next" do |links|
      get links.first["href"]
    end

    assert_response :success
    assert_select "[data-testid='exchange-history-item']", count: 1
    assert_select "nav[aria-label='Pagination for exchanges']", text: /Page 2 of 2/
  end

  test "index excludes deleted sources" do
    sign_in_as(@user)
    deleted_source = create_secondary_source
    deleted_source.update!(deleted_at: Time.current)

    get budget_sources_path(@budget)

    assert_response :success
    assert_select "[data-testid='source-card']", count: 1
    assert_select "[data-testid='source-card']", text: /#{@source.name}/
    assert_select "[data-testid='source-card']", text: /#{deleted_source.name}/, count: 0
    assert_select "[data-deleted]", count: 0
  end

  test "new offers supported icons colours and available budget currencies" do
    sign_in_as(@user)

    get new_budget_source_path(@budget)

    assert_response :success
    assert_select "input[name='source[icon]'][type='radio']", count: Source.icon_options.size
    assert_select "input[name='source[icon]'][value='wallet'][checked]"
    assert_select "input[name='source[icon]'][value='wallet'][aria-label='Wallet']"
    assert_select "label[title='Wallet']", text: ""
    assert_select "input[name='source[colour]'][type='radio']", count: Source.colour_options.size
    assert_select "input[name='source[colour]'][value='green'][checked]"
    assert_select "input[name='source[amount]'][type='text'][inputmode='decimal'][placeholder='0'][data-controller='amount-fields']"
    assert_select "input[name='source[amount]'][value='0']"
    assert_select "input[name='source[amount]'][data-amount-fields-start-value='0']"
    assert_select "select[name='source[currency_code]'] option[value='USD'][selected]"
    assert_select "select[name='source[currency_code]'] option[value='EUR']"
    assert_select "select[name='source[currency_code]'][data-currency-picker-target='select']"
    assert_select "input[type='search'][placeholder='Search by name or code'][data-currency-picker-target='filter']"
    assert_select "input[role='combobox'][aria-autocomplete='list'][aria-expanded='true']"
    assert_select "[data-currency-search-icon] .icon[style*='--icon-search']"
    assert_select "dialog#currency-picker-dialog[data-currency-picker-target='currencyDialog'][aria-label='Choose a currency']"
    assert_select "button[data-currency-picker-target='currencyTrigger'][aria-haspopup='dialog']"
    assert_select "input[type='radio'][value='USD'][checked]"
    assert_select "label[data-currency-picker-target='option'][data-filter-value='USD US Dollar, 🇺🇸']:not([hidden])"
    assert_select "[data-currency-picker-option]:first-child > label input[value='USD'][checked]"
    assert_select "label[data-currency-picker-target='option']:not([hidden])", count: Currency.options.size
    assert_select "[data-currency-picker-target='emptyState'][hidden]"
    assert_select "input[name='source[rate]'][type='text'][inputmode='decimal'][required][data-controller='amount-fields'][data-currency-fields-target='rate']"
    assert_select "input[name='source[rate]'][data-amount-fields-fraction-digits-value='12']"
    assert_select "output[data-currency-fields-target='converted']", count: 0
    assert_select "[data-currency-fields-target='rateFields'][hidden]"
    assert_select "dialog#currency-rate-picker-dialog[data-currency-rate-picker-target='dialog'][aria-label='Confirm conversion rate']"
    assert_select "button[data-currency-rate-picker-target='trigger'][aria-haspopup='dialog']"
    assert_select "form[data-controller~='form'][data-controller~='currency-fields'][data-currency-fields-base-currency-value='USD']"
    assert_select "form[data-controller~='currency-fields'][data-currency-fields-reference-link-value='#{currency_reference_path}']"
    assert_select "[data-currency-fields-target='rateStatus']", count: 0
    assert_select "dialog[data-currency-rate-picker-target='dialog'] button[data-appearance='keycap']", text: "Apply"
    assert_select "input[name='source[amount]'][data-currency-fields-target='amount']"
  end

  test "new hides keyboard tips on mobile devices" do
    sign_in_as(@user)

    get new_budget_source_path(@budget), headers: {
      "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148"
    }

    assert_response :success
    assert_select "form kbd", count: 0
    assert_select "form input[autofocus]", count: 0
    assert_select "form[data-form-focused-on-toggle-value='false']"
  end

  test "new shows keyboard tips on desktop devices" do
    sign_in_as(@user)

    get new_budget_source_path(@budget), headers: {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
    }

    assert_response :success
    assert_select "form kbd"
    assert_select "form[data-form-focused-on-toggle-value='true']"
  end

  test "creates a source from catalog values" do
    sign_in_as(@user)

    assert_difference("Source.count", 1) do
      post budget_sources_path(@budget), params: {
        source: {
          name: "Emergency fund",
          amount: "125.5000",
          currency_code: "USD",
          rate: "1.25",
          icon: "building-bank",
          colour: "blue"
        }
      }
    end

    source = @budget.sources.order(:created_at, :id).last
    assert_redirected_to budget_sources_path(@budget)
    assert_equal "Emergency fund", source.name
    assert_equal BigDecimal("125.5000"), source.amount
    assert_equal BigDecimal("1"), source.rate
    assert_equal "building-bank", source.icon
    assert_equal "blue", source.colour
  end

  test "invalid source creates no record and rerenders options" do
    sign_in_as(@user)

    assert_no_difference("Source.count") do
      post budget_sources_path(@budget), params: {
        source: {
          name: "",
          amount: "-1",
          currency_code: "USD",
          icon: "unknown",
          colour: "unknown"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Name can't be blank/
    assert_select "input[name='source[icon]'][type='radio']", count: Source.icon_options.size
    assert_select "input[name='source[colour]'][type='radio']", count: Source.colour_options.size
  end

  test "show displays source details" do
    sign_in_as(@user)

    get source_path(@source)

    assert_response :success
    assert_select "main[data-size='lg'] > article[data-elevation='1']:not([style])"
    assert_select "h1", text: @source.name
    assert_select "article > header > nav > .icon-wrap[style*='color: var(--color-palette-green)']"
    assert_select "section[data-layout='grid'][aria-label='Source summary']"
    assert_select "[data-testid='source-initial-amount']", text: /Initial amount.*1,500.25 USD.*Added when this source was created/m
    assert_select "[data-testid='source-available-amount']", text: /Available now.*1,375.25 USD.*After expenses and exchanges/m
    assert_select "[data-testid='source-budget'] a[href='#{budget_expenses_path(@budget)}']", text: @budget.date_period
    assert_select "a[aria-label='Back to sources'][href='#{budget_sources_path(@budget)}']"
    assert_select "[data-testid='expense-card']", count: 1
    assert_select "[data-testid='expense-day-total']", text: /125 USD/
    assert_select "a[href='#{new_source_exchange_path(@source)}']", text: /Make exchange/
    assert_select "form[action='#{source_path(@source)}'] button[aria-label='Remove source']" do
      assert_select ".icon"
    end
  end

  test "show paginates expenses connected to the source" do
    sign_in_as(@user)
    other_source = create_secondary_source
    @budget.expenses.create!(source: other_source, amount: 1, occurred_on: @budget.period_from)
    15.times do |index|
      @budget.expenses.create!(
        source: @source,
        amount: 1,
        occurred_on: @budget.period_from + index.days,
        note: "Source expense #{index}"
      )
    end

    get source_path(@source)

    assert_response :success
    assert_select "[data-testid='expense-card']", count: 15
    assert_select "nav[aria-label='Pagination for source expenses']", text: /Page 1 of 2/
    assert_select "nav[aria-label='Pagination for source expenses'] a", text: "Next" do |links|
      get links.first["href"]
    end

    assert_response :success
    assert_select "[data-testid='expense-card']", count: 1
    assert_select "nav[aria-label='Pagination for source expenses']", text: /Page 2 of 2/
  end

  test "show labels deleted historical sources" do
    sign_in_as(@user)
    deleted_source = create_secondary_source
    deleted_source.update!(deleted_at: Time.current)

    get source_path(deleted_source)

    assert_response :success
    assert_select "small", text: "Deleted"
    assert_select "a[href='#{new_source_exchange_path(deleted_source)}']", count: 0
    assert_select "button[aria-label='Remove source']", count: 0
  end

  test "cannot access another user's budget or source" do
    sign_in_as(@user)

    get budget_sources_path(budgets(:other))
    assert_response :not_found

    get source_path(sources(:other))
    assert_response :not_found
  end

  private
    def create_secondary_source
      @budget.sources.create!(
        name: "Secondary source",
        amount: 100,
        currency_code: "USD",
        icon: "wallet",
        colour: "green"
      )
    end
end
