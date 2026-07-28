require "net/http"
require "json"

class HomeController < ApplicationController
    before_action :set_logged_in
    def index
      if not @loggedin
        render "guest"
      else
        get_hackatime_projects
      end
    end
end
