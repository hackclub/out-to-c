require "net/http"

class AuthController < ApplicationController
    before_action :require_logged_in, only: %i[ hackatime_callback ]
    # used for dev login
    def dev
        if !Rails.env.development?
            redirect_to root_path
            return
        end

        target_uid = params["uid"]

        # find user with that id
        existing_user = User.where(uid: target_uid).first()
        if existing_user == nil
            redirect_to root_path, notice: "error: Dev login failed because user doesn't exist"
        return
        end

        session[:user_id] = existing_user
        redirect_to root_path, notice: "Dev login successful!"
    end
    def hca_callback
        puts "hi, im gonna try to authenticate now :3"
        
        if params["code"] == nil or params["code"].blank?
            redirect_to root_path, notice: "Missing authentication code"
            return
        end

        # exchange code for token
        uri = URI.parse('https://auth.hackclub.com/oauth/token')
        data = '{
            "client_id": "'+ ENV["HCA_CLIENT_ID"]+ '",
            "client_secret": "'+ ENV["HCA_SECRET"]+ '",
            "redirect_uri": "' + url_for(only_path: false) + '",
            "code": "' + params["code"] + '",
            "grant_type": "authorization_code"
        }'
        headers = {'content-type': 'application/json'}
        res = Net::HTTP.post(uri, data, headers)

        token = ""

        # whether the authentication was unsuccesful
        error = (not (res.kind_of? Net::HTTPSuccess)) or res.body.include? "error"

        if not error
            data = JSON.parse(res.body)

            if data == nil or data["access_token"] == nil
                # mark authentication as unsuccesful
                error = true
            else
                token = data["access_token"]
            end
        end

        if error
            redirect_to root_path, notice: "Invalid authentication code or authentication server was unreachable"
        else
        # get the user's slackID from the hackclub auth api
        uri = URI.parse("https://auth.hackclub.com/oauth/userinfo")
        puts token
        headers = {'Authorization': 'Bearer ' + token}

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            req = Net::HTTP::Get.new(uri)
            req['Authorization'] = 'Bearer ' + token
            response = http.request(req)
            response
        end
        
        if not (response.kind_of? Net::HTTPSuccess)
            redirect_to root_path, notice: "Problem fetching user info"
            return
        end

        body = response.body
        user_data = JSON.parse(body)

        if user_data == nil or user_data["slack_id"] == nil
            redirect_to root_path, notice: "Bad user info"
            return
        end

        slack_id = user_data["slack_id"]

        # try to find existing user
        existing_user = User.where(uid:slack_id).first()

        if existing_user == nil
            puts "NEW USER ALERT!!!"
            
            # get new user's slack username and profile picture using the cachet api
            slack_data = get_slack_data(slack_id)
            
            # construct the new user :3
            user = User.new({"uid":slack_id, "hca_token":token, "name":slack_data[:name], "pfp":slack_data[:pfp], "last_island":0})
            puts slack_data
            session[:user_id] = user
            user.save
            redirect_to root_path, notice: "welcome, new user named: "+user.name
        else
            puts "WELCOME back"
            # returning user, only update the token,
            # and log in the user session.

            existing_user["hca_token"] = token

            session[:user_id] = existing_user
            existing_user.save
            redirect_to root_path, notice: "welcome back, user named:"+existing_user.name
        end
        end
    end
    def hackatime_callback
        error = params["error"]
        if error != nil
            msg = "Error: "+error
            if error == "access_denied"
                msg = "Canceled login"
            end
            redirect_to root_path, notice: msg
            return
        end
        code = params["code"]
        if code == nil || code.blank?
            redirect_to root_path, notice: "error: Missing authentication code"
            return
        end

        # exchange code for token
        response = get_token(code)

        if response[:token] == nil
            redirect_to root_path, notice: "error: Couldn't get token: " + response[:error].to_s
            return
        end
        token = response[:token]

        user_data = get_user_data(token)
        slack_id = user_data["slack_id"]

        # check for existing user
        @user.token = token
        @user.save
        # existing user
        redirect_to root_path, notice: "linked hackatime, user named:"+@user.name
    end

    def test
        if not Rails.env.development?
            render plain: "sorry! this endpoint isnt allowed in production!!"
            return
        end
        slack_id = params["id"]
        render plain: get_slack_data(slack_id)
    end

    private
        def get_user_data(token)
            uri = URI.parse("https://hackatime.hackclub.com/api/v1/authenticated/me")
            req = Net::HTTP::Get.new(uri)
            req["Authorization"] = "Bearer " + token
            res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
                http.request(req)
            end

            JSON.parse(res.body)
        end

        # gets user data from slack.
        # if a slack bot has been set in .env, will use that to get user data,
        # else will query cachet api (https://cachet.dunkirk.sh/)
        def get_slack_data(slack_id)
            if ENV["SLACK_BOT_TOKEN"] == nil
                return get_slack_data_cachet(slack_id)
            end

            uri = URI.parse("https://slack.com/api/users.info?user="+slack_id)
            data = '{
                "user": "'+ slack_id + '",
            }'
            headers = {
                'content-type': "application/json",
                'Authorization': "Bearer " + ENV["SLACK_BOT_TOKEN"]
            }
            res = Net::HTTP.post(uri, data, headers)

            # fallback on cachet api
            if not (res.kind_of? Net::HTTPSuccess)
                return get_slack_data_cachet(slack_id)
            end

            data = JSON.parse(res.body)

            if data == nil or data["user"] == nil
                return get_slack_data_cachet(slack_id)
            end

            { "pfp": data["user"]["profile"]["image_512"], "name": data["user"]["profile"]["display_name"] }
        end

        # get slack data through cachet api
        def get_slack_data_cachet(slack_id)
            uri = URI.parse("https://cachet.dunkirk.sh/users/"+slack_id)
            req = Net::HTTP::Get.new(uri)
            res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
                http.request(req)
            end
            data = JSON.parse(res.body)
            { "pfp": data["imageUrl"], "name": data["displayName"] }
        end

        # exchange a authentication code for a hackatime user token
        def get_token(code)
            uri = URI.parse("https://hackatime.hackclub.com/oauth/token")
            data = '{
                "client_id": "'+ ENV["HACKATIME_UID"]+ '",
                "client_secret": "'+ ENV["HACKATIME_SECRET"]+ '",
                "redirect_uri": "' + url_for(only_path: false) + '",
                "code": "' + params["code"] + '",
                "grant_type": "authorization_code"
            }'
            headers = { 'content-type': "application/json" }
            res = Net::HTTP.post(uri, data, headers)

            # whether the authentication was unsuccesful
            error = (not (res.kind_of? Net::HTTPSuccess)) or res.body.include? "error"

            if error
                { "error": "Error from hackatime API" }
            else
                data = JSON.parse(res.body)
                if data == nil or data["access_token"] == nil
                    { "error": "Bad response from hackatime API" }
                else
                    { "token": data["access_token"] }
                end
            end
        end
end
