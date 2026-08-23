require 'fastimage'

class VoyageController < ApplicationController
  # require all routes of the voyage controller to be logged in to an account
  before_action :require_logged_in
  # require dev endpoints to be in development environment
  before_action :dev_check, only: %i[ add_hour wipe_slack_convo delete_force wipe_slack_channel]

  def delete
    if @voyage == nil
      redirect_to root_path, notice: "Error: Voyage doesn't exist"
      return
    end
    if @voyage.ship_status != 0
      redirect_to root_path, notice: "Error: Can't delete already shipped Voyage! Ship status: " + @voyage.ship_status.to_s 
      return
    end
    delete_internal()
  end

  def delete_force
    delete_internal()
  end

  def wipe_slack_channel
    wipe_internal(params["id"])
    redirect_to root_path
  end

  def wipe_slack_convo
    id = slack_open_conversation(@user.uid)
    wipe_internal(id)
    redirect_to root_path
  end

  def ship
    if @voyage == nil
      render json: { "error": "No voyage to ship" }
      return
    end
    if @voyage.ship_status != 0
      render json: { "error": "Voyage is already shipped! Ship status: " + @voyage.ship_status.to_s }
      return
    end
    if @voyage.name == nil or @voyage.name.blank?
      render json: { "error": "Voyage name is empty" }
      return
    end
    if @voyage.desc == nil or @voyage.desc.blank?
      render json: { "error": "Voyage description is empty" }
      return
    end
    if @voyage.repo == nil or @voyage.repo.blank?
      render json: { "error": "Voyage repository is unset" }
      return
    end
    if @voyage.hackatime == nil or @voyage.hackatime.blank?
      render json: { "error": "Voyage is not linked to any hackatime project" }
      return
    end
    if @voyage.image_link == nil or @voyage.image_link.blank?
      render json: { "error": "Voyage has no screenshot set!" }
      return
    end
    if @voyage.total_seconds / 60 / 60 < @voyage.last_island
      render json: { "error": "Voyage has less time tracked than required for the selected prices. Did you change the hackatime project to one with less time?" }
      return
    end
    if @user.email == nil or @user.email.blank?
      render json: { "error": "Your user has no email set. Ask an admin for help!" }
      return
    end

    if params["github_username"] != nil and not params["github_username"].blank?
      @user.github_username = params["github_username"]
      @user.save!
    end
    
    if @user.github_username == nil or @user.github_username.blank?
      render json: { "error": "Your user has no GitHub username set. Ask an admin for help!" }
      return
    end

    if ENV["DISABLE_AIRTABLE"] == nil or ENV["DISABLE_AIRTABLE"].blank?
      if @voyage.airtable_entry == nil or @voyage.airtable_entry.blank?
        render json: { "error": "Voyage airtable entry not found! Ask an admin for help!" }
        return
      end
    end
    for k in ["first_name","last_name","birthday","address_1","city","country","state","zip"]
      if params[k] == nil or params[k].blank?
        render json: { "error": "Missing key '#{k}'" }
        return
      end
    end
    @voyage.ship_date = Time.now
    start = Date.strptime(ysws_start, "%Y-%m-%d").strftime("%m/%d/%Y")
    date_range = start + "-" + @voyage.ship_date.strftime("%m/%d/%Y")

    if ENV["DISABLE_AIRTABLE"] == nil or ENV["DISABLE_AIRTABLE"].blank?
      # send PII to airtable
      AirtableEntry.update(@voyage.airtable_entry, {
        "Email": @user.email,
        "GitHub Username": @user.github_username,
        "Justification - Submitter Hackatime ID": @user.hackatime_id.to_s,
        "Justification - Hackatime Project Name(s) + Date Range(s)": "#{@voyage.hackatime} #{date_range}",
        "First Name": params["first_name"],
        "Last Name": params["last_name"],
        "Birthday": params["birthday"],
        "Address (Line 1)": params["address_1"],
        "Address (Line 2)": params["address_2"],
        "City": params["city"],
        "Country": params["country"],
        "State / Province": params["state"],
        "ZIP / Postal Code": params["zip"],
      })
    end

    # valid ship probably !
    aid = ENV["REVIEWER_CHANNEL_ID"]
    id = slack_open_conversation(@user.uid)

    @voyage.ship_status = 1
    @voyage.save

    # send message to reviewer
    if @voyage_name_trim == nil or @voyage_name_trim.blank?
      generate_desc_trimmed()
    end
    slack_send_message_conversation(aid, ":shipitparrot: New ship alert !!\n<@" + @user.uid + "> just shipped `"+ @voyage_name_trim + "`, " + (@voyage.total_seconds / 60 / 60).to_i.to_s + " hours.\nPrices: `" + @voyage.cargo + "`\n<#{reviewer_url+"/edit/"+@voyage.id.to_s}|Review>")

    # send message to user!
    slack_send_message_conversation(id, "Good work captain !! Your project has been shipped! :yay::yay:\n\nYour project will be reviewed soon and after that you will receive your prices! :sos-heidi-treasure::3c:\nDM <@" + ENV["ADMIN_SLACK_ID"] + "> if you have any questions!\n\n/pirate orph' <3")

    render json: { "ok": "yay" }
  end

  def price
    if @voyage.ship_status != 0
      render json: { "error": "Voyage is shipped, no prices can be claimed at this point. Ask for support in #out-to-c. Ship status: " + @voyage.ship_status.to_s }
      return
    end
    get_next_island
    if not @found_island
      render json: { "error": "You cant claim this item, @found_island not found" }
      return
    end
    price = params["selection"]
    if not @found_prices.has_key?(price.to_sym)
      render json: { "error": "You cant claim this item, @found_prices doesn't include this item" }
      return
    end

    details = [price, @found_prices[price.to_sym][:name]]
    img = ActionController::Base.helpers.asset_path("prices/"+ price + ".png")
    @voyage.last_island = @next_island
    @voyage.cargo = @voyage.cargo + price + ","
    puts @voyage.cargo
    @voyage.save
    get_next_island
    
    fp = 0
    if @found_island
      fp = JSON.parse(@found_prices.to_json)
      fp.each_with_index do | x, i |
          x[1]["src"] = ActionController::Base.helpers.asset_path("prices/"+x[0].to_s+".png")
      end
    end


    render json: { "ok": 1, "price":details, "img": img, "next_island_remaining": @next_island - ( @voyage.total_seconds / 60 / 60), "fp": fp }
  end
  def add_hour
    if @voyage.ship_status != 0
      return
    end
    if @voyage.total_seconds == nil
      @voyage.total_seconds = 0.0
    end
    @voyage.total_seconds += 60*60
    @voyage.save!
  end
  def new
    if @voyage != nil
      # editing voyage !
      # todo: back up old version?

      if @voyage.ship_status == 2
        if @user.past_voyages == nil
          @user.past_voyages = ""
        end
        @user.past_voyages = @user.past_voyages + @user.voyage.to_s + ","
        @user.voyage = 0
        @user.save
        @voyage = nil
      elsif @voyage.ship_status != 0
        render json: { "error": "Shipped voyage can't be editted! Ship status: " + @voyage.ship_status.to_s }
        return
      end
    end
    if params["name"].strip.empty?
      render json: { "error": "Name required." }
      return
    end
    hackatime_project_exists = false
    time = 0
    if params["hackatime"] == nil
      params["hackatime"] = ""
    end
    if params["hackatime"].strip.empty?
      hackatime_project_exists = true
    else
      if @projects == nil or @projects.length == 0
        get_hackatime_projects
      end
      for project in @projects
        if project["name"] == params["hackatime"]
          time = project["total_seconds"]
          hackatime_project_exists = true
          break
        end
      end
    end
    if not hackatime_project_exists
      render json: { "error": "Hackatime project doesn't exist" }
      return
    end
    if params["demo"] != nil and not params["demo"].blank? and is_invalid_url(params["demo"])
      render json: { "error": "Demo URL must be blank or a valid link!" }
      return
    end
    if params["repo"] != nil and not params["repo"].blank? and is_invalid_url(params["repo"])
      render json: { "error": "Repository URL must be blank or a valid link!" }
      return
    end
    
    image_link = ""

    if @voyage != nil
      image_link = @voyage.image_link
    end

    if params["image_data"] != nil
      upload_data = upload_image(params["image_data"])
      if upload_data[:error] != nil
        render json: { "error": upload_data[:error]}
        return
      end
      image_link = upload_data[:ok]
    end

    data = {
      "name": params["name"],
      "total_seconds": time,
      "desc": params["desc"],
      "demo": params["demo"],
      "repo": params["repo"],
      "hackatime": params["hackatime"],
      "ship_status": 0,
      "reviewer_note": "",
      "justification": "",
      "image_link": image_link,
      "cargo": "",
      "owner": @user.id,
      "last_island":0
    }
    if @voyage != nil
      # keep voyage data
      data["cargo"] = @voyage["cargo"]
      data["last_island"] = @voyage["last_island"]
      data["reviewer_note"] = @voyage["reviewer_note"]
      data["ship_status"] = @voyage["ship_status"]
      data["justification"] = @voyage["justification"]
      @voyage.update(data)
    else
      @voyage = Voyage.new(data)
    end

    # set user's voyage to this voyage!

    # sync to airtable
    airtable_data = 
      {
        "Email": @user.email,
        "GitHub Username": @user.github_username,
        "Description": @voyage.desc,
        "Code URL": @voyage.repo,
        "Playable URL": @voyage.demo,
      }
    if @voyage.image_link
      airtable_data[:Screenshot] = [{"url": @voyage.image_link}]
    end

    if ENV["DISABLE_AIRTABLE"] == nil or ENV["DISABLE_AIRTABLE"].blank?
      if @voyage.airtable_entry == nil or @voyage.airtable_entry.blank?
        entry = AirtableEntry.create(airtable_data)
        @voyage.airtable_entry = entry.id.to_s
        @voyage.save!
      else
        AirtableEntry.update(@voyage.airtable_entry, airtable_data)
      end
    end

    @voyage.save!
    @user.voyage = @voyage.id
    session[:user_id] = @user
    @user.save!

    get_next_island()

    fp = 0
    if @found_prices.length > 0
      fp = []
      fp = JSON.parse(@found_prices.to_json)
      fp.each_with_index do | x, i |
          x[1]["src"] = ActionController::Base.helpers.asset_path("prices/"+x[0].to_s+".png")
      end
    end

    generate_desc_trimmed()
    generate_hackatime_text()

    render json: { "name": @voyage_name_trim, "fp":fp, "desc": @voyage_desc_trim, "repo": @voyage_repo_trim, "repo_url": @voyage.repo, "hackatime-text": @hackatime_text, "id": @voyage.id, "total_seconds": @voyage.total_seconds, "next_island_remaining": @next_island - ( @voyage.total_seconds / 60 / 60) }
  end

  private
    def is_invalid_url(link)
      begin
        if link == nil or link.blank?
          return true
        end
        uri = URI(link)
        (uri.scheme != "https") and (uri.scheme != "http")
      rescue
        true
      end
    end
    def delete_internal
      @voyage.delete()
      @user.voyage = nil
      @user.save!
      session[:user_id] = @user
      redirect_to root_path
    end
    def wipe_internal(id)
      url = URI("https://slack.com/api/conversations.history?channel="+id)
      req = Net::HTTP::Get.new(url)
      req["Authorization"] = "Bearer " + ENV["SLACK_BOT_TOKEN"]
      res = Net::HTTP.start(url.hostname, url.port, use_ssl: url.scheme == "https") { |http|
        http.request(req)
      }
      puts res.body
      data = JSON.parse(res.body)
      messages = data["messages"]
      for message in messages
        if message["bot_profile"] != nil and message["bot_profile"]["name"] == "Pirate Orph'"
          url = URI("https://slack.com/api/chat.delete")
          body = { "channel": id, "ts":message["ts"] }
          headers = { 'Content-Type': 'application/json', "Authorization": "Bearer " + ENV["SLACK_BOT_TOKEN"]  }
          res = Net::HTTP.post(url, body.to_json, headers)
        end
      end
    end
    def dev_check
      if !Rails.env.development?
        redirect_to root_path
      end
    end
end
