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
            ["Awaiting Approval",@awaiting_approval],
            ["Unshipped",@unshipped],
            ["Shipped",@shipped],
        ]
    end

    private
        def admin_check
            if @user == nil or @user.uid != ENV["ADMIN_SLACK_ID"]
                redirect_to root_path
                return
            end
        end
end
