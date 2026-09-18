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
            elsif v.ship_status == 1 and v.fraud_suspected != true
                @awaiting_approval.append(v)
            elsif v.ship_status == 2
                @shipped.append(v)
            end
        end

        @sections = [
            ["Awaiting Approval",@awaiting_approval,"a-awaiting",true],
            ["Approved Ships",@shipped,"a-shipped",false],
        ]
        @fraud_or_reviewer = "reviewer"
    end
    
    def fraud
        @all_voyages = Voyage.all
        # @unshipped = []
        @suspected = []
        @not_approved = []
        @approved = []
        @users = User.all

        for v in @all_voyages
            if v.ship_status == 0
                # @unshipped.append(v)
            else
                if v.fraud_suspected == true
                    @suspected.append(v)
                elsif v.ship_status == 2
                    if v.fraud_approved == true
                        @approved.append(v)
                    else
                        @not_approved.append(v)
                    end
                end
            end
        end

        @sections = [
            ["Suspected fraud / time inflation",@suspected,"a-suspected",true],
            ["Awaiting fraud approval",@not_approved,"a-awaiting",true],
            ["Fraud approved",@approved,"a-shipped",false],
        ]
        @fraud_or_reviewer = "fraud"
        render "index"
    end

    def edit
        id = params["id"]
        @voyage = Voyage.find(id)
        if @voyage.ship_status == 0
            redirect_to reviewer_path
            return
        end
        @reviewing = true
        @owner = User.find(@voyage.owner)
    end

    def mark_suspected
        @voyage = Voyage.find(params["id"])
        @voyage.fraud_suspected = true
        @voyage.fraud_approved = false
        @voyage.save
        redirect_to reviewer_path
    end

    def fraud_approve
        @voyage = Voyage.find(params["id"])
        @voyage.fraud_suspected = false
        @voyage.fraud_approved = true
        @voyage.fraud_approved_by = @user.uid
        @voyage.save!
        aid = slack_open_conversation(ENV["ADMIN_SLACK_ID"])
        slack_send_message_conversation(aid,"`#{@voyage.name}` was Fraud Approved by <@#{@user.uid}>\n<#{reviewer_url+"/edit/"+@voyage.id.to_s}|Review>")
        redirect_to fraud_path
    end

    def fraud_edit
        edit()
        @reviewing = false
        render "edit"
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
        @voyage.additional_justification = params["additional_justification"]
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
                @voyage.approval_date = Time.now
            end
        end
        if @voyage.ship_status == 2
            if @owner.seconds_offset == nil
                @owner.seconds_offset = 0
            end
            if @owner.all_prizes == nil
                @owner.all_prizes = ""
            end
            @owner.all_prizes = @owner.all_prizes + @voyage.cargo
            @owner.seconds_offset += @voyage.total_seconds
            @owner.last_island = @voyage.last_island
            @owner.save
        end

        @voyage.save

        if @voyage.ship_status == 2
            if ENV["DISABLE_AIRTABLE"] == nil or ENV["DISABLE_AIRTABLE"].blank?
                AirtableEntry.update(@voyage.airtable_entry, {
                    "Justification - Specific Technical Features": @voyage.justification,
                    "Justification - Additional Justification": @voyage.additional_justification,
                    "Optional - Override Hours Spent": @voyage.total_seconds / 60.0 / 60.0,
                })
            end
        end

        if not rereview
            review_message = ""
            for line in @voyage.reviewer_note.split("\n")
                review_message += ">" + line.strip + "\n"
            end

            if @voyage.ship_status == 2
                # generate NPS fillout form:
                if ENV["DISABLE_AIRTABLE"] == nil or ENV["DISABLE_AIRTABLE"].blank?
                    nps = ENV["NPS_FILLOUT_URL"] + "?id=" + @voyage.airtable_entry.to_s
                else
                    nps = "AIRTABLE_ENTRY_HERE"
                end
                slack_send_message_conversation(id,":yayayayayay: Your project has been approved by <@#{@user.uid}> :yayayayayay:\n#{review_message}\nYou will be DMd by <@#{ENV["ADMIN_SLACK_ID"]}> shortly about fulfilment ! :sos-heidi-treasure::treasure-box:\n\nIt would mean a lot to me if you took a second to fill out <#{nps}|this feedback form> !\n\n/yours truly--pirate orph'")

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
