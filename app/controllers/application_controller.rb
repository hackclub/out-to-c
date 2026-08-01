require "net/http"
require "json"

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :get_islands, :get_prices

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes


  private
    def get_islands
      @islands = [6,12,24]
    end
    def get_next_island
      @next_island = 999
      @island_indx = 0
      last = 0
      if @voyage != nil
        last=@voyage.last_island
      end
      for island in @islands
        if island > last
          @next_island = island
          break
        end
        @island_indx += 1
      end
      @found_island = false
      @found_prices = []
      if @voyage != nil and @voyage.total_seconds >= @next_island * 60 * 60
        @found_island = true
        @found_prices = @prices[@island_indx]
      end
    end
    def get_prices
      @prices = [
        {
          "blahaj":{"name":"Blåhaj"},
          "pinecil":{"name":"Pinecil"},
          "pizero2w":{"name":"Pi Zero 2W"},
        },
      
        {
          "pico8":{"name":"Pico-8"},
          "pipico":{"name":"Pi Pico"},
          "cloudflare":{"name":"$12 Cloudflare Domain Grant"},
        },
      
        {
          "tbd":{"name":"To Be Defined..."},
          "tbd":{"name":"To Be Defined..."},
          "tbd":{"name":"To Be Defined..."},
        },
      ]
    end
    def set_logged_in
      @loggedin = session[:user_id] != nil and session[:user_id]["uid"] != nil
      if @loggedin
        @user = User.find(session[:user_id]["id"])
        if @user.voyage != nil
          @voyage = Voyage.find(@user.voyage)
        end
      end
    end
    def ysws_start
      date = "2026-08-02T22:00:00.000Z"
      # TODO: REPLACE DATE BEFORE LAUNCH
      date = "2026-07-07T22:00:00.000Z"

      date
    end
    def require_logged_in
      set_logged_in
      if not @loggedin
        redirect_to root_path
      end
    end
    def get_hackatime_projects
      token = @user.token
      if token == nil
        @projects = []
        return
      end

      url = URI("https://hackatime.hackclub.com/api/v1/authenticated/projects?include_archived=false&projects=&since=&until=&until_date=&start="+ysws_start+"&end=&start_date=&end_date=")
      req = Net::HTTP::Get.new(url)
      req["Authorization"] = "Bearer " + token
      res = Net::HTTP.start(url.hostname, url.port, use_ssl: url.scheme == "https") { |http|
        http.request(req)
      }
      data = JSON.parse(res.body)
      @projects = data["projects"]
    end
end
