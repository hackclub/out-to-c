require "net/http"
require "json"

class HomeController < ApplicationController
    before_action :set_logged_in
    def index
      if not @loggedin
        render "guest"
      end
      get_hackatime_projects
    end

    private
      def set_logged_in
        @loggedin = session[:user_id] != nil and session[:user_id]["uid"] != nil
        if @loggedin
          @user = User.find(session[:user_id]["id"])
          if @user.voyage != nil
            @voyage = Voyage.find(@user.voyage)
          end
        end
      end
      def get_hackatime_projects
        token = @user.token

        date = "2026-08-02T22:00:00.000Z"
        # TODO: REPLACE DATE BEFORE LAUNCH
        date = "2026-07-07T22:00:00.000Z"

        url = URI("https://hackatime.hackclub.com/api/v1/authenticated/projects?include_archived=false&projects=&since=&until=&until_date=&start="+date+"&end=&start_date=&end_date=")
        req = Net::HTTP::Get.new(url)
        req["Authorization"] = "Bearer " + token
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: url.scheme == "https") { |http|
          http.request(req)
        }
        data = JSON.parse(res.body)
        @projects = data["projects"]
      end
end
