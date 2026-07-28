class VoyageController < ApplicationController
  # require all routes of the voyage controller to be logged in to an account
  before_action :require_logged_in
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
    if params["name"].strip.empty?
      render json: { "error": "Name required." }
      return
    end
    hackatime_project_exists = false
    get_hackatime_projects
    for project in @projects
      if project["name"] == params["hackatime"]
        hackatime_project_exists = true
        break
      end
    end
    if not hackatime_project_exists or params["hackatime"].strip.empty?
      render json: { "error": "Hackatime project doesn't exist" }
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
    def require_logged_in
      set_logged_in
    end
end
