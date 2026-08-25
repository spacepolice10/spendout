require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "Cybercat answers according to today's remaining spending percentage" do
    assert_equal "That’s enough spending for today.", cybercat_spending_answer(0)
    assert_equal "You can, but tomorrow will be tighter.", cybercat_spending_answer(24.99)
    assert_equal "Better save some for tomorrow.", cybercat_spending_answer(25)
    assert_equal "Yep, still good to go.", cybercat_spending_answer(50)
    assert_equal "You’re ahead today—nice.", cybercat_spending_answer(80)
  end

  test "Cybercat notices when nothing has been spent" do
    assert_equal "Nothing spent yet—nice.", cybercat_spending_answer(0, no_expenses: true)
  end
end
