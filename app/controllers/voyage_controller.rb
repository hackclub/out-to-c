class VoyageController < ApplicationController
  # require all routes of the voyage controller to be logged in to an account
  before_action :require_logged_in
  # require dev endpoints to be in development environment
  before_action :dev_check, only: %i[ add_hour ]

  def delete
    @voyage.delete()
    @user.voyage = nil
    @user.save!
    session[:user_id] = @user
    redirect_to root_path
  end
  def ship
    if @voyage == nil
      render json: { "error": "No voyage to ship" }
      return
    end
    if @voyage.name == nil or @voyage.name.blank?
      render json: { "error": "Voyage name is empty" }
      return
    end
    if @voyage.desc == nil or @voyage.desc.blank?
      render json: { "error": "Voyage description is empty" }
      return
    end
    if @voyage.repo == nil or @voyage.repo.blank?
      render json: { "error": "Voyage repository is unset" }
      return
    end
    if @voyage.hackatime == nil or @voyage.hackatime.blank?
      render json: { "error": "Voyage is not linked to any hackatime project" }
      return
    end
    # valid ship probably !
    
  end
  def price
    get_next_island
    if not @found_island
      render json: { "error": "You cant claim this item, @found_island not found" }
      return
    end
    price = params["selection"]
    if not @found_prices.has_key?(price.to_sym)
      render json: { "error": "You cant claim this item, @found_prices doesn't include this item" }
      return
    end

    details = [price, @found_prices[price.to_sym][:name]]
    img = ActionController::Base.helpers.asset_path("prices/"+ price + ".png")
    @voyage.last_island = @next_island
    @voyage.cargo = @voyage.cargo + price + ","
    puts @voyage.cargo
    @voyage.save
    get_next_island
    
    fp = 0
    if @found_island
      fp = JSON.parse(@found_prices.to_json)
      fp.each_with_index do | x, i |
          x[1]["src"] = ActionController::Base.helpers.asset_path("prices/"+x[0].to_s+".png")
      end
    end


    render json: { "ok": 1, "price":details, "img": img, "next_island_remaining": @next_island - ( @voyage.total_seconds / 60 / 60), "fp": fp }
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
      # editing voyage !
      # todo: back up old version?
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
      if @projects == nil or @projects.length == 0
        get_hackatime_projects
      end
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
      "repo": params["repo"],
      "hackatime": params["hackatime"],
      "cargo":"",
      "last_island":0
    }
    if @voyage != nil
      # keep voyage data
      data["cargo"] = @voyage["cargo"]
      data["last_island"] = @voyage["last_island"]
      @voyage.update(data)
    else
      @voyage = Voyage.new(data)
    end
    @voyage.save!

    # set user's voyage to this voyage!
    @user.voyage = @voyage.id
    @user.save!
    session[:user_id] = @user

    get_next_island()

    fp = 0
    if @found_prices.length > 0
      fp = []
      fp = JSON.parse(@found_prices.to_json)
      fp.each_with_index do | x, i |
          x[1]["src"] = ActionController::Base.helpers.asset_path("prices/"+x[0].to_s+".png")
      end
    end

    generate_desc_trimmed()
    generate_hackatime_text()

    render json: { "name": @voyage_name_trim, "fp":fp, "desc": @voyage_desc_trim, "repo": @voyage_repo_trim, "repo_url": @voyage.repo, "hackatime-text": @hackatime_text, "id": @voyage.id, "total_seconds": @voyage.total_seconds, "next_island_remaining": @next_island - ( @voyage.total_seconds / 60 / 60) }
  end

  private
    def dev_check
      if !Rails.env.development?
        redirect_to root_path
      end
    end
end
