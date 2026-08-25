class UsersController < ApplicationController
  def show
    @budget = Current.user.current_budget
  end
end
