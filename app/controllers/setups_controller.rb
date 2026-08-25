class SetupsController < ApplicationController
  allow_unauthenticated_access
  before_action :require_empty_installation

  def new
    @user = User.new(role: :administrator)
  end

  def create
    @user = User.new(setup_params.merge(role: :administrator))

    User.transaction do
      raise ActiveRecord::RecordNotUnique if User.exists?
      @user.save!
    end

    start_new_session_for(@user)
    redirect_to root_path, notice: "Your administrator account is ready."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique
    redirect_to new_session_path, alert: "This installation has already been set up."
  end

  private
    def require_empty_installation
      redirect_to new_session_path if User.exists?
    end

    def setup_params
      params.expect(user: %i[ email_address password password_confirmation ])
    end
end
