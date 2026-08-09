class AdminController < ApplicationController
    before_action :set_logged_in
    before_action :admin_check

    layout "admin"

    def index
        @all_voyages = Voyage.all
        @unshipped = []
        @awaiting_approval = []
        @shipped = []
        @users = User.all

        for v in @all_voyages
            if v.ship_status == 0
                @unshipped.append(v)
            elsif v.ship_status == 1
                @awaiting_approval.append(v)
            elsif v.ship_status == 2
                @shipped.append(v)
            end
        end

        @sections = [
            ["Awaiting Approval",@awaiting_approval,"a-awaiting"],
            ["Unshipped",@unshipped,"a-unshipped"],
            ["Shipped",@shipped,"a-shipped"],
        ]
    end

    def edit
        id = params["id"]
        @voyage = Voyage.find(id)
        @owner_id = @voyage.owner
        @owner = User.find(@owner_id)
        get_hackatime_projects_with_token(@owner.token)
    end

    def submit_edit
        @voyage = Voyage.find(params["id"])
        @voyage.name = params["name"]
        @voyage.desc = params["desc"]
        @voyage.repo = params["repo"]
        @voyage.hackatime = params["hackatime"]
        @voyage.cargo = params["cargo"]
        @voyage.reviewer_note = params["reviewer_note"]
        @voyage.justification = params["justification"]
        @voyage.ship_status = params["ship_status"]
        @voyage.save
        redirect_to admin_path
        puts @voyage.to_json
    end

    def raw
        @voyage = Voyage.find(params["id"])
        render json: JSON.pretty_generate(@voyage.as_json)
    end

    def reload_reviewer_list
        Dotenv.overload('.env')
        render plain:"reloaded .env!\n\nreviewer list: \"" + ENV["REVIEWERS"].to_s + "\""
    end

    private
        def admin_check
            if @user == nil or @user.uid != ENV["ADMIN_SLACK_ID"]
                redirect_to root_path
                return
            end
        end
end
