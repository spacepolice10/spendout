require "test_helper"

class CurrencyReferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.write(CurrencyReference::CACHE_KEY, {
      "reference_date" => Date.current.iso8601,
      "rates" => { "EUR" => "1", "USD" => "1.2", "VND" => "30000" }
    })
  end

  teardown do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "requires authentication" do
    get currency_reference_path, params: { from: "USD", to: "VND" }

    assert_redirected_to new_session_path
  end

  test "returns the cached table normalized against USD by default" do
    sign_in_as users(:one)

    get currency_reference_path, as: :json

    assert_response :success
    assert_equal "USD", response.parsed_body.fetch("base")
    assert_equal({ "USD" => "1", "EUR" => "0.833333333333", "VND" => "25000" },
      response.parsed_body.fetch("rates"))
  end

  test "normalizes the table against a requested base" do
    sign_in_as users(:one)

    get currency_reference_path, params: { base: "EUR" }, as: :json

    assert_response :success
    assert_equal "EUR", response.parsed_body.fetch("base")
    assert_equal({ "EUR" => "1", "USD" => "1.2", "VND" => "30000" },
      response.parsed_body.fetch("rates"))
  end
end
