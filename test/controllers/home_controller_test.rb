require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "landing is public and invites a visitor to try Spendout" do
    get landing_path

    assert_response :success
    assert_select "title", text: /Spendout — Everyday money, under control/
    assert_select "meta[name='description'][content*='safe to spend today']"
    assert_select "main[data-page='landing']"
    assert_select "[data-landing-header]", count: 0
    assert_select "[data-hero-cybercat] img[alt='Cybercat'][width='100']", count: 1
    assert_select "[data-hero-cybercat] h1", text: "Spendout", count: 1
    assert_select "[data-floating-ui], [data-float]", count: 0
    assert_select "[data-landing-fuel] [role='progressbar'][aria-valuenow='68.0']", count: 1
    assert_select "[data-landing-fuel] [data-daily-gauge] > header h2", count: 0
    assert_select "[data-landing-fuel] [data-remainder-gauge-needle][transform='rotate(32.4 120 118)']", count: 1
    assert_select "[data-control-notes] article > span[aria-hidden='true']", count: 3
    assert_select "[data-section-number]", count: 0
    assert_select "a[role='button'][href='#{new_session_path}']", text: "Try Spendout", minimum: 1
    assert_select "nav[aria-label='Budget sections']", count: 0
  end

  test "landing sends an authenticated visitor to their budget without showing the tab bar" do
    sign_in_as(@user)
    get landing_path

    assert_response :success
    assert_select "a[role='button'][href='#{root_path}']", text: "Open my budget", minimum: 1
    assert_select "nav[aria-label='Budget sections']", count: 0
  end

  test "landing distinguishes available behavior from planned work" do
    get landing_path

    assert_select "[data-rate-example]", text: /1 USD.*26,300 VND/
    assert_select "small", text: /No external rate service/
    assert_select "[data-landing-ownership]", text: /currently deployed with Kamal/
    assert_select "[data-landing-ownership]", text: /ONCE is planned/
    assert_select "[data-landing-footer]", text: /planned, not yet available/
  end
end
