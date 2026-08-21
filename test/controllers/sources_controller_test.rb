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
    assert_select "[data-testid='source-card']", count: 1
    assert_select "[data-testid='source-card']", text: /Main source/
    assert_select "a[aria-label='New source'][href='#{new_budget_source_path(@budget)}']"
    assert_select "a[aria-label='Back to budget'][href='#{budget_path(@budget)}']"
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
    assert_select "input[name='source[amount]'][type='text'][inputmode='decimal'][placeholder='0'][data-controller='money-input']"
    assert_select "input[name='source[amount]'][value]", count: 0
    assert_select "input[name='source[amount]'][data-money-input-start-value]", count: 0
    assert_select "select[name='source[currency_code]'] option[value='USD'][selected]"
    assert_select "select[name='source[currency_code]'] option[value='EUR']"
    assert_select "input[name='source[rate]'][value='1.0']"
    assert_select "form[data-controller='currency-conversion'][data-currency-conversion-base-currency-value='USD']"
    assert_select "input[name='source[amount]'][data-currency-conversion-target='amount']"
    assert_select "input[name='source[rate]'][data-currency-conversion-target='rate']"
    assert_select "small[data-currency-conversion-target='result'][aria-live='polite']"
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
    assert_redirected_to source_path(source)
    assert_equal "Emergency fund", source.name
    assert_equal BigDecimal("125.5000"), source.amount
    assert_equal BigDecimal("1.25"), source.rate
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
    assert_select "h1", text: @source.name
    assert_select "dd", text: /1,500.25 USD/
    assert_select "a[aria-label='Back to sources'][href='#{budget_sources_path(@budget)}']"
  end

  test "show labels deleted historical sources" do
    sign_in_as(@user)
    deleted_source = create_secondary_source
    deleted_source.update!(deleted_at: Time.current)

    get source_path(deleted_source)

    assert_response :success
    assert_select "small", text: "Deleted"
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
