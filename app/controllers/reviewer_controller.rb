class ReviewerController < ApplicationController
    before_action :set_logged_in
    before_action :reviewer_check

    helper_method :trim_length_fixed

    layout "admin"

    def index
        @all_voyages = Voyage.all
        # @unshipped = []
        @awaiting_approval = []
        @shipped = []
        @users = User.all

        for v in @all_voyages
            if v.ship_status == 0
                # @unshipped.append(v)
            elsif v.ship_status == 1
                @awaiting_approval.append(v)
            elsif v.ship_status == 2
                @shipped.append(v)
            end
        end

        @sections = [
            ["Awaiting Approval",@awaiting_approval,"a-awaiting",true],
            ["Approved Ships",@shipped,"a-shipped",false],
        ]
    end

    def edit
        id = params["id"]
        @voyage = Voyage.find(id)
        @owner = User.find(@voyage.owner)
    end

    def submit_edit
        @voyage = Voyage.find(params["id"])
        if @voyage == nil
            render json: { "error": "Voyage not found" }
            return
        end
        if @voyage.ship_status == 0
            render json: { "error": "Can't edit unshipped voyage with reviewer permissions. Contact admin." }
            return
        end
        if @voyage.ship_status == 2
            # project is already approved, this is a re-review
            if params["approved"] == "false"
                # reviewer cant un-approve an already approved project,
                # as the user will already have gotten messaged on slack.
                #
                # they can only change the reviewer note.
                render json: { "error": "Reviewer cant un-approve an already approved project. Contact admin." }
                return
            end
        end
        @voyage.reviewer_note = params["reviewer_note"]
        if params["approved"] == "true"
            @voyage.ship_status = 2
        elsif params["approved"] == "false"
            @voyage.ship_status = 0
        else
            render json: { "error": "Bad value of 'approved', :"+params["approved"].to_s }
            return
        end
        @voyage.save
        render json: { "ok": 1 }
    end

    private
        def reviewer_check
            # todo: fix
            if @user == nil or @user.uid != ENV["ADMIN_SLACK_ID"]
                redirect_to root_path
                return
            end
        end
end
