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
    assert_select "[data-cybercat-dialog] p", text: "I live on your server now.", count: 1
    assert_select "[data-hero-cybercat] h1", text: "Spendout", count: 1
    assert_select "[data-landing-hero] strong", text: "what's safe to spend today."
    assert_select "[data-landing-hero]", text: /No subscription\. No lock-in\. Run it yourself\./
    assert_select "[data-landing-hero]", text: /And it has looks, by the way\./
    assert_select "[data-landing-price]", text: "$0 · self-hosted · your server, your data"
    assert_select "[data-landing-steps]", count: 0
    assert_select "[data-floating-ui], [data-float]", count: 0
    assert_select "[data-landing-fuel] [data-daily-gauge][data-controller='daily-gauge']", count: 1
    assert_select "[data-landing-fuel] [data-gauge-bolts][aria-hidden='true'] span", count: 4
    assert_select "[data-landing-fuel] [role='progressbar'][aria-valuenow='68.0']", count: 1
    assert_select "[data-landing-fuel] [data-daily-gauge] > header h2", count: 0
    assert_select "[data-landing-fuel] [data-remainder-gauge-needle][transform='rotate(32.4 120 118)']", count: 1
    assert_select "[data-control-notes][data-rate-copy] article", count: 1 do
      assert_select "h3", text: "A signal. Never a gate."
      assert_select "strong", text: "never touches this number"
    end
    assert_select "[data-landing-chapter] > header h2", text: "Your daily fuel gauge."
    assert_select "[data-landing-chapter]", text: /stress down|keeping you calm/, count: 0
    assert_select "[data-section-number]", count: 0
    assert_select "a[role='button'][href='#{new_session_path}']", text: "Try Spendout", minimum: 1
    assert_select "[data-landing-actions] a[role='button'][href='https://github.com/spacepolice10/spendout']", text: "GitHub", count: 1
    assert_select "nav[aria-label='Budget sections']", count: 0
  end

  test "landing sends an authenticated visitor to their budget without showing the tab bar" do
    sign_in_as(@user)
    get landing_path

    assert_response :success
    assert_select "a[role='button'][href='#{root_path}']", text: "Open my budget", minimum: 1
    assert_select "[data-landing-footer] a[role='button'][href='#{root_path}']", text: "Open my budget", count: 1
    assert_select "nav[aria-label='Budget sections']", count: 0
  end

  test "landing distinguishes available behavior from planned work" do
    get landing_path

    assert_select "[data-currency-story] [data-rate-board]", count: 1
    assert_select "[data-rate-board][data-controller]", count: 0
    assert_select "[data-rate-board] table", count: 1
    assert_select "[data-rate-board] caption", text: /dated reference rates.*confirm the direct quote/m
    assert_select "[data-rate-board-status]", text: "Sample rates"
    assert_select "[data-rate-board] tbody tr", count: 4
    assert_select "[data-rate-board]", text: /Pound sterling/, count: 0
    assert_select "[data-rate-display]", text: "26,300"
    assert_select "[data-rate-board-snapshots-value]", count: 0
    assert_select "[data-currency-story] [data-rate-copy] article", count: 1
    assert_select "[data-currency-story] [data-rate-copy] h3", text: "Real currencies. Honest history."
    assert_select "[data-landing-chapter] > header h2", text: "Speaks your currency."
    assert_select "[data-currency-story] [data-rate-copy]", text: /base currency stays fixed/
    assert_select "[data-currency-story] [data-rate-copy]", text: /saved amounts never revalue themselves/
    assert_select "[data-landing-letter]" do
      assert_select "h2", text: "Why I made Spendout"
      assert_select "p", text: /expense tracking simple, free, and reasonable/
      assert_select "p", text: /modern Rails stack/
      assert_select "p", text: /open nature.*specific requirements/m
      assert_select "p", text: /financial data.*helps manage it/m
      assert_select "footer", text: "— Vlad Kov"
    end
    assert_select "#details > header h2", text: "Features"
    assert_select "#details > header p", text: "Quick highlights."
    assert_select "[data-detail-grid] article", count: 9
    assert_select "[data-detail-grid] h3", text: "Categorize spending"
    assert_select "[data-detail-grid] h3", text: "Categories style themselves"
    assert_select "[data-detail-grid] article", text: /automatically suggests a fitting icon.*and colour/m
    assert_select "[data-detail-grid] h3", text: "Confirm every rate"
    assert_select "[data-detail-grid] h3", text: "Exchange between sources"
    assert_select "[data-detail-grid] h3", text: "Add useful context"
    assert_no_match(/we buy|we sell/i, response.body)
    assert_select "[data-landing-ownership]", text: /currently deployed with Kamal/
    assert_select "[data-landing-ownership]", text: /ONCE-ready version.*first-run administrator setup.*backup and restore hooks/m
    assert_select "[data-landing-ownership] a[href='https://github.com/spacepolice10/spendout/tree/codex/once-adaptation']", text: "Install with ONCE ↗"
    assert_select "[data-deployment-terminal]", text: /once deploy ghcr\.io\/spacepolice10\/spendout:latest.*--host spendout\.example\.com/m
    assert_select "[data-landing-footer]", count: 1 do
      assert_select "strong", text: "Demo data is temporary."
      assert_select "p", text: /not preserved.*removed within a week/m
      assert_select "a[role='button'][href='#{new_session_path}']", text: "Try the demo"
    end
  end
end
