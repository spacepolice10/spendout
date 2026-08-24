class Current < ActiveSupport::CurrentAttributes
  attribute :session, :timezone, :suggested_currency_code
  delegate :user, to: :session, allow_nil: true
end
