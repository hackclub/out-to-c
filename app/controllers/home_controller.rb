class HomeController < ApplicationController
    before_action :set_logged_in
    def index
      if not @loggedin
        render "guest"
      else
        get_hackatime_projects
        update_voyage_time
        generate_hackatime_text
        get_next_island
        generate_desc_trimmed
      end
    end
    private
      def update_voyage_time
        if @voyage == nil || @voyage.hackatime.strip.empty?
          return
        end
        
        for a in @projects
          if a["name"] == @voyage.hackatime
            @voyage.total_seconds = a["total_seconds"]
            @voyage.save
            return
          end
        end
      end
end
