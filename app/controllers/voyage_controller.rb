class VoyageController < ApplicationController
  # require all routes of the voyage controller to be logged in to an account
  before_action :check_logged_in
  # require dev endpoints to be in development environment
  before_action :dev_check, only: %i[ delete add_hour ]

  def delete
    @voyage.delete()
    @user.voyage = nil
    @user.save!
    session[:user_id] = @user
    redirect_to root_path
  end
  def add_hour
    if @voyage.hours == nil
      @voyage.hours = 0.0
    end
    @voyage.hours += 1.0
    @voyage.save!
  end
  def new
    if @voyage != nil
      render json: { "error": "This user already has an active voyage!" }
      return
    end
    data = {
      "name": params["name"],
      "desc": params["desc"],
      "hackatime": params["hackatime"]
    }
    @voyage = Voyage.new(data)
    @voyage.save!

    # set user's voyage to this voyage!
    @user.voyage = @voyage.id
    @user.save!
    session[:user_id] = @user

    render json: { "id": @voyage.id }
  end

  private
    def dev_check
      if !Rails.env.development?
        redirect_to root_path
      end
    end
    def check_logged_in
      loggedin = session[:user_id] != nil and session[:user_id]["uid"] != nil
      if not loggedin
        redirect_to root_path
      end
      @user = User.find(session[:user_id]["id"])
      if @user.voyage != nil
        @voyage = Voyage.find(@user.voyage)
      end
    end
end
