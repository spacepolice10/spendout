class ApplicationController < ActionController::Base
  include Authentication
  include CurrentTimezone

  before_action :set_request_variant

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def current_user
    Current.user
  end

  private
    def set_request_variant
      request.variant = :mobile if request.user_agent.to_s.match?(/Android|iPhone|iPad|iPod|IEMobile|Opera Mini/i)
    end
end
