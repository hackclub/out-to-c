class AdminController < ApplicationController
    before_action :set_logged_in
    before_action :admin_check

    helper_method :trim_length_fixed

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

    def prize_fulfilment
        @partial = []
        @awaiting_fulfilment = []
        @fulfilled = []
        @users = User.all

        for u in User.all
            if u.all_prizes == nil or u.all_prizes.blank?
                next
            end
            all_voyages = ""
            if u.past_voyages != nil
                all_voyages += u.past_voyages
            end
            if u.voyage != nil
                all_voyages += u.voyage.to_s
            end
            valid_voyages = 0
            for vi in all_voyages.split(",")
                v = Voyage.find(vi)
                if v.ship_status != 2 or v.fraud_approved != true
                    next
                end
                valid_voyages += 1
            end
            if valid_voyages == 0
                next
            end

            if u.fulfilled_prizes == nil or u.fulfilled_prizes.blank?
                @awaiting_fulfilment.append(u)
            elsif u.fulfilled_prizes == u.all_prizes
                @fulfilled.append(u)
            else
                @partial.append(u)
            end
        end

        @sections = [
            ["Awaiting Fulfilment",@awaiting_fulfilment,"a-awaiting"],
            ["Partial fulfilment",@partial,"a-awaiting"],
            ["Fulfilled",@fulfilled,"a-shipped"],
        ]
    end

    def prize_fulfilment_save
        @user = User.find(params["id"])
        @user.fulfilled_prizes = params["text"]
        @user.save
    end

    def edit
        id = params["id"]
        @voyage = Voyage.find(id)
        @owner_id = @voyage.owner
        @owner = User.find(@owner_id)
        @projects = get_hackatime_projects_with_token(@owner.token)[:projects]
    end

    def submit_edit
        @voyage = Voyage.find(params["id"])
        image_link = @voyage.image_link
        if params["image_data"] != nil
            upload_data = upload_image(params["image_data"])
            if upload_data[:error] != nil
                render json: { "error": upload_data[:error]}
                return
            end
            image_link = upload_data[:ok]
        end
        @voyage.image_link = image_link
        @voyage.name = params["name"]
        @voyage.desc = params["desc"]
        @voyage.repo = params["repo"]
        @voyage.demo = params["demo"]
        @voyage.hackatime = params["hackatime"]
        @voyage.cargo = params["cargo"]
        @voyage.reviewer_note = params["reviewer_note"]
        @voyage.justification = params["justification"]
        @voyage.ship_status = params["ship_status"]
        @voyage.save
        redirect_to admin_path
        puts @voyage.to_json
    end

    def raw_user
        @user = User.find(params["id"])
        render json: JSON.pretty_generate(@user.as_json)
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
