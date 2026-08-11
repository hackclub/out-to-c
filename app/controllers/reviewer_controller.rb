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
        if @voyage.ship_status == 0
            redirect_to reviewer_path
            return
        end
        @owner = User.find(@voyage.owner)
    end

    def submit_edit
        @voyage = Voyage.find(params["id"])
        @owner = User.find(@voyage.owner)

        if @voyage == nil
            render json: { "error": "Voyage not found" }
            return
        end
        no_conflict = params["updated"] == @voyage.updated_at.to_s

        if not no_conflict
            if @voyage.ship_status == 0
                render json: { "error": "Conflict detected! This project was rejected by someone else while you were on this page. Your changes have been discarded." }
                return
            end
            render json: { "error": "Conflict detected! This project was approved reviewed by someone else while you were on this page. Your changes have been discarded. You can reload the current page to see actual updated state." }
            return
        end
        if @voyage.ship_status == 0
            render json: { "error": "Can't edit unshipped voyage with reviewer permissions. Contact admin." }
            return
        end

        rereview = @voyage.ship_status == 2
        if rereview
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
        @voyage.justification = params["justification"]
        if params["approved"] == "true"
            @voyage.ship_status = 2
        elsif params["approved"] == "false"
            @voyage.ship_status = 0
        else
            render json: { "error": "Bad value of 'approved', :"+params["approved"].to_s }
            return
        end
        if not rereview
            # prepare DMs to both the user with the status update, and
            # to the admin to notify them about fulfilment.
            id = slack_open_conversation(@owner.uid)
            
            if @voyage.ship_status == 2
                aid = slack_open_conversation(ENV["ADMIN_SLACK_ID"])
            end
        end

        @voyage.save

        if @voyage.ship_status == 2
            AirtableEntry.update(@voyage.airtable_entry, {
                "Optional - Override Hours Spent Justification": @voyage.justification
            })
        end

        if not rereview
            review_message = ""
            for line in @voyage.reviewer_note.split("\n")
                review_message += ">" + line.strip + "\n"
            end

            if @voyage.ship_status == 2
                slack_send_message_conversation(id,":yayayayayay: Your project has been approved by <@#{@user.uid}> :yayayayayay:\n#{review_message}\nYou will be DMd by <@#{ENV["ADMIN_SLACK_ID"]}> shortly about fulfilment ! :sos-heidi-treasure::treasure-box:\n\n/yours truly--pirate orph'")
                slack_send_message_conversation(aid,":exclamation:Project approved:exclamation::yay:\nFulfilment time! <@#{@owner.uid}> shipped '#{trim_length_fixed(@voyage.name,25)}' which was approved by <@#{@user.uid}>.\nCargo: `#{@voyage.cargo}`")
            elsif @voyage.ship_status == 0
                slack_send_message_conversation(id,"Your project was rejected by <@#{@user.uid}> :<\n#{review_message}\nPlease make the changes specified and reship your project!\n\n/pirate orph'")
            end
        end

        render json: { "ok": 1 }
    end

    private
        def reviewer_check
            @reviewers = ENV["REVIEWERS"].split(",")
            if @user == nil or not @reviewers.include?(@user.uid)
                redirect_to root_path
                return
            end
        end
end
