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
  def price
    get_next_island
    if not @found_island
      render json: { "error": "You cant claim this item" }
      return
    end
    price = params["selection"]
    puts price
    if not @found_prices.has_key?(price.to_sym)
      render json: { "error": "You cant claim this item" }
      return
    end

    @user.last_island = @next_island
    @voyage.cargo = @voyage.cargo + price + ","
    puts @voyage.cargo
    @voyage.save
    @user.save
    get_next_island

    render json: { "ok": 1, "next_island_remaining": @next_island - ( @voyage.total_seconds / 60 / 60) }
  end
  def add_hour
    if @voyage.total_seconds == nil
      @voyage.total_seconds = 0.0
    end
    @voyage.total_seconds += 60*60
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
    time = 0
    if params["hackatime"] == nil
      params["hackatime"] = ""
    end
    if params["hackatime"].strip.empty?
      hackatime_project_exists = true
    else
      get_hackatime_projects
      for project in @projects
        if project["name"] == params["hackatime"]
          time = project["total_seconds"]
          hackatime_project_exists = true
          break
        end
      end
    end
    if not hackatime_project_exists
      render json: { "error": "Hackatime project doesn't exist" }
      return
    end
    data = {
      "name": params["name"],
      "total_seconds": time,
      "desc": params["desc"],
      "hackatime": params["hackatime"],
      "cargo":""
    }
    @voyage = Voyage.new(data)
    @voyage.save!

    # set user's voyage to this voyage!
    @user.voyage = @voyage.id
    @user.save!
    session[:user_id] = @user

    get_next_island()

    render json: { "id": @voyage.id, "total_seconds": @voyage.total_seconds, "next_island_remaining": @next_island - ( @voyage.total_seconds / 60 / 60) }
  end

  private
    def dev_check
      if !Rails.env.development?
        redirect_to root_path
      end
    end
end
