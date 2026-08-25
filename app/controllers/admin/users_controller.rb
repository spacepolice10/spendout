class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(:email_address)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(role: :member))

    if @user.password.blank? && !ActionMailer::Base.perform_deliveries
      @user.errors.add(:base, "Configure email delivery before adding a code-only user.")
      return render :new, status: :unprocessable_entity
    end

    if @user.save
      deliver_initial_code unless @user.password_digest?
      redirect_to admin_users_path, notice: account_created_notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.expect(user: %i[ email_address password password_confirmation ])
    end

    def deliver_initial_code
      AuthCode.produce(@user.email_address)
    end

    def account_created_notice
      if @user.password_digest?
        "#{@user.email_address} can now sign in with the password you set."
      else
        "#{@user.email_address} was added and sent a sign-in code."
      end
    end
end
