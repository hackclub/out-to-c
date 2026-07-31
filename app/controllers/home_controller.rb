class HomeController < ApplicationController
    before_action :set_logged_in
    def index
      if not @loggedin
        render "guest"
      else
        if @voyage == nil
          get_hackatime_projects
        else
          @projects = []
          update_voyage_time
        end
        get_next_island
      end
    end
    private
      def get_next_island
        @next_island = 999
        indx = 0
        for island in @islands
          if island > @user.last_island
            @next_island = island
            break
          end
          indx += 1
        end
        @found_island = false
        @found_prices = []
        if @voyage != nil and @voyage.total_seconds >= @next_island * 60 * 60
          @found_island = true
          @found_prices = @prices[indx]
        end
      end
      def update_voyage_time
        if @voyage == nil || @voyage.hackatime.strip.empty?
          return
        end
        token = @user.token
        params = { projects: @voyage.hackatime }
        encoded_query = URI.encode_www_form(params)
        url = URI("https://hackatime.hackclub.com/api/v1/authenticated/projects?include_archived=false&#{encoded_query}&since=&until=&until_date=&start="+ysws_start+"&end=&start_date=&end_date=")
        req = Net::HTTP::Get.new(url)
        req["Authorization"] = "Bearer " + token
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: url.scheme == "https") { |http|
          http.request(req)
        }
        data = JSON.parse(res.body)
        p = data["projects"][0]["total_seconds"]
        @voyage.total_seconds = p
        @voyage.save
      end
end
