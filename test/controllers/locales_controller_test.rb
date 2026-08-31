require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  test "stores a supported locale and returns to the referring page" do
    patch locale_path, params: { locale: "ru" }, headers: { "HTTP_REFERER" => new_session_url }

    assert_redirected_to new_session_url
    assert_response :see_other
    assert_equal "ru", cookies[:locale]

    follow_redirect!
    assert_select "h2", text: "Введите адрес электронной почты"
    assert_select "form[action='#{locale_path}'] button[disabled]", text: "Русский"
  end

  test "rejects an unsupported locale" do
    patch locale_path, params: { locale: "unsupported" }

    assert_response :unprocessable_entity
    assert_nil cookies[:locale]
  end

  test "uses the browser language until the user makes an explicit choice" do
    get new_session_path, headers: { "Accept-Language" => "ru-RU,ru;q=0.9,en;q=0.8" }

    assert_response :success
    assert_select "h2", text: "Введите адрес электронной почты"

    cookies[:locale] = "en"
    get new_session_path, headers: { "Accept-Language" => "ru-RU,ru;q=0.9" }

    assert_select "h2", text: "Enter your e-mail"
  end
end
