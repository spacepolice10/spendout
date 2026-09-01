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
    assert_select "[data-landing-header]", count: 1
    assert_select "[data-landing-header] [data-landing-brand]", text: "Spendout"
    assert_select "[data-landing-header] [data-landing-brand] img[src='/icon-32.png']", count: 1
    assert_select "[data-landing-header-mobile]", count: 0
    assert_select "[data-landing-header] nav a[href='#{landing_path(anchor: "details")}']", text: "Features"
    assert_select "[data-landing-header] nav a[href='#{tour_path(feature: "sources")}']", text: "Tour"
    assert_select "[data-landing-header] nav a[href='#{once_path}']", text: "ONCE"
    assert_select "[data-landing-header] nav a[href='#{once_path}'] .icon[style*='--icon-brand-once']"
    assert_select "[data-landing-header-actions] a[href='#{new_session_path}']", text: "Try Spendout"
    assert_select "[data-landing-header-actions] a[href='https://github.com/spacepolice10/spendout']", text: "GitHub" do
      assert_select ".icon[style*='--icon-brand-github']", count: 1
    end
    assert_select "[data-hero-cybercat], [data-cybercat-dialog]", count: 0
    assert_select "[data-landing-hero] h1", text: "Know what you can spend."
    assert_select "[data-landing-hero] strong", text: "what's safe to spend today."
    assert_select "[data-landing-hero]", text: /No subscription\. No lock-in\. Run it yourself\./
    assert_select "[data-landing-hero]", text: /And it has looks, by the way\./
    assert_select "[data-landing-price]", text: "$0 · self-hosted · your server, your data"
    assert_select "[data-landing-steps]", count: 0
    assert_select "[data-floating-ui], [data-float]", count: 0
    assert_select "[data-landing-fuel] [data-daily-gauge][data-controller='daily-gauge']", count: 1
    assert_select "[data-control-layout] > [data-landing-demo-frame] > [data-landing-fuel]", count: 1
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
    assert_select "[data-landing-hero] a[href='https://github.com/spacepolice10/spendout']", count: 0
    assert_select "[data-landing-hero] [data-feature-chips]", count: 0
    assert_select "#details [data-feature-chips] > [data-feature-chip-cloud] a", count: Tour::FEATURES.size
    assert_select "#details [data-feature-chips] a[href='#{tour_path(feature: "sources")}']", text: "Create a source"
    assert_select "#details [data-feature-chips] a[href='#{tour_path(feature: "language")}']", text: "Change the language"
    assert_select "#details [data-landing-actions] a[role='button'][href='#{tour_path(feature: "sources")}']", text: "Take the tour", count: 1
    assert_select "nav[aria-label='Budget sections']", count: 0
  end

  test "landing uses a disclosure header on mobile" do
    get landing_path, headers: { "User-Agent" => "Mozilla/5.0 (iPhone) Mobile" }

    assert_response :success
    assert_select "[data-landing-header] > div", count: 0
    assert_select "[data-landing-header-mobile]", count: 1
    assert_select "[data-landing-header-mobile] > summary", text: /Spendout/
    assert_select "[data-landing-header-mobile] > summary .icon[style*='--icon-chevron-right']"
    assert_select "[data-landing-header-mobile] nav a[href='#{landing_path}']", text: "Home"
    assert_select "[data-landing-header-mobile] nav a[href='#{landing_path(anchor: "details")}']", text: "Features"
    assert_select "[data-landing-header-mobile] nav a[href='#{new_session_path}']", text: "Try Spendout"
  end


  test "tour is public and links to one page per feature" do
    get tour_path

    assert_response :success
    assert_select "title", text: /Tour Spendout/
    assert_select "main[data-page='tour']"
    assert_select "[data-tour-bar]", count: 0
    assert_select "[data-landing-header]", count: 1
    assert_select "[data-landing-header] [data-landing-brand]", text: "Spendout"
    assert_select "[data-landing-header] nav a[href='#{landing_path(anchor: "details")}']", text: "Features"
    assert_select "[data-tour-slide='welcome']", count: 1
    assert_select "[data-tour-screen]", count: 0
    assert_select "a[href='#{tour_path(feature: "sources")}']", text: /Start the tour/
    assert_select "nav[aria-label='Budget sections']", count: 0

    Tour::FEATURES.each do |feature, attrs|
      get tour_path(feature: feature)

      assert_response :success
      assert_select "[data-tour-slide]", count: 1
      assert_select "[data-tour-screen] img", count: 1
      assert_select "[data-tour-screen] img[src*='#{File.basename(attrs[:image], ".*")}']", count: 1
      assert_select "h1", text: attrs[:title]
      assert_select "h2", text: attrs[:detail_title]
      assert_select "[data-tour-count]", count: 0
      assert_select "[data-tour-lead]", count: 0
      assert_select "[data-tour-pager]", count: 1
    end
  end

  test "landing sends an authenticated visitor to their budget without showing the tab bar" do
    sign_in_as(@user)
    get landing_path

    assert_response :success
    assert_select "a[role='button'][href='#{root_path}']", text: "Open my budget", minimum: 1
    assert_select "[data-landing-header-actions] a[href='#{root_path}']", text: "Open my budget"
    assert_select "[data-landing-footer] a[role='button'][href='#{root_path}']", text: "Open my budget", count: 1
    assert_select "nav[aria-label='Budget sections']", count: 0
  end

  test "landing distinguishes available behavior from planned work" do
    get landing_path

    assert_select "[data-currency-story] [data-rate-board]", count: 1
    assert_select "[data-currency-story] > [data-landing-demo-frame] > [data-rate-board]", count: 1
    assert_select "[data-rate-board][data-controller]", count: 0
    assert_select "[data-rate-board] table", count: 1
    assert_select "[data-rate-board] caption", count: 0
    assert_select "[data-rate-board-status]", count: 0
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
    assert_select "[data-feature-chips] a", count: 15
    assert_select "[data-feature-chips] a", text: "Create a source"
    assert_select "[data-feature-chips] a", text: "Plan the spending"
    assert_select "[data-feature-chips] a", text: "Track an expense"
    assert_select "[data-feature-chips] a", text: "Read the daily gauge"
    assert_select "[data-feature-chips] a", text: "Finish a plan"
    assert_select "[data-feature-chips] a", text: "Check the reports"
    assert_select "[data-feature-chips] a", text: "Control account"
    assert_select "[data-feature-chips] a", text: "Change the language"
    assert_select "[data-feature-chips] a", text: "Deploy with ONCE"
    assert_select "[data-feature-chips] a", text: "Enter a rate"
    assert_select "[data-coming]", count: 0
    assert_no_match(/we buy|we sell/i, response.body)
    assert_select "[data-landing-ownership]", text: /currently deployed with Kamal/
    assert_select "[data-landing-ownership]", text: /ONCE-ready version.*first-run administrator setup.*backup and restore hooks/m
    assert_select "[data-landing-ownership] a[href='#{once_path}']", text: "Install with ONCE"
    assert_select "[data-deployment-terminal]", text: /once deploy ghcr\.io\/spacepolice10\/spendout:latest.*--host spendout\.example\.com/m
    assert_select "[data-landing-footer]", count: 1 do
      assert_select "strong", text: "Demo data is temporary."
      assert_select "p", text: /not preserved.*removed within a week/m
      assert_select "a[role='button'][href='#{new_session_path}']", text: "Try the demo"
    end
  end

  test "once setup page is public and walks through the install" do
    get once_path

    assert_response :success
    assert_select "title", text: /Install Spendout with ONCE/
    assert_select "meta[name='description'][content*='machine you control']"
    assert_select "main[data-page='once']"
    assert_select "[data-landing-header] nav a[href='#{once_path}']", text: "ONCE"
    assert_select "[data-landing-header] nav a[href='#{once_path}'] .icon[style*='--icon-brand-once']"
    assert_select "[data-once-intro] h1", text: /Spendout/
    assert_select "[data-once-version]", text: "ONCE-ready"
    assert_select "[data-once-intro] h2", text: /Put it on your own server/
    assert_select "[data-once-intro] a[href='https://github.com/spacepolice10/spendout/tree/codex/once-adaptation']", text: "ONCE-ready branch"
    assert_select "[data-once-intro] a[href='https://osaasy.dev/']", text: "O'Saasy"
    assert_select "main[data-page='once'][data-size='lg'] > div[data-layout='grid'] > article[data-elevation='1']", count: 4
    assert_select "main[data-page='once'] article > header > hgroup", count: 4
    assert_select "main[data-page='once'] article > section", count: 13
    assert_select "main[data-page='once'] pre > code", text: "curl https://get.once.com | sh"
    assert_select "main[data-page='once'] pre > code", text: "once deploy ghcr.io/spacepolice10/spendout:latest --host spendout.example.com"
    assert_select "main[data-page='once']", text: /password of at least 12 characters/
    assert_select "main[data-page='once']", text: /SMTP_ADDRESS/
    assert_select "main[data-page='once']", text: /MAILER_FROM_ADDRESS/
    assert_select "main[data-page='once']", text: /pre-backup/
    assert_select "main[data-page='once'] strong", text: "Strict (full)"
    assert_select "main[data-page='once'] a[href='https://github.com/basecamp/once']", text: "ONCE README"
    assert_select "main[data-page='once'] a[href='https://once.com/']", text: "once.com"
    assert_select "[data-landing-footer] a[role='button'][href='#{new_session_path}']", text: "Try the demo"
    assert_select "nav[aria-label='Budget sections']", count: 0
  end
end
