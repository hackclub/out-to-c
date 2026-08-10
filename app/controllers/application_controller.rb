require "net/http"
require "json"

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :get_islands, :get_prices

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes


  private
    # checks that an uploaded file is an image,
    # and that it is not animated.
    # returns json response.
    # also returns the file data in the 'data' key if it is read. (since file reads exhaust the file object)
    def is_image_valid(file)
      allowed_types = ["jpeg","jpg","png","webp"]
      type = FastImage.type(file)
      if type == nil
        return {"error":"File is not recognized as an image"}
      end
      valid_type = allowed_types.include? type.to_s
      if not valid_type
        return {"error":"Image type is not allowed. Allowed types are "+allowed_types.join(", ")}
      end
      file_data = file.read
      if type.to_s == "png" and is_png_animated(file_data)
        return {"error":"Animated PNGs are not allowed","data":file_data}
      end
      if type.to_s == "webp" and is_webp_animated(file_data)
        return {"error":"Animated images are not allowed","data":file_data}
      end
      puts type.to_s
      puts "type^"

      # success state!
      # the file data is returned, as the file data
      # can only be read once from a single file object,
      # and since it is used here, the file data also needs
      # to be returned so that it can be used
      {"data":file_data,"type":type.to_s}
    end

    # reads png file data to determine if it is animated
    def is_png_animated(data)
      idat_pos = data.index('IDAT')
      idat_pos != nil and data[0..idat_pos].index('acTL') != nil 
    end

    # checks if webp is animated
    def is_webp_animated(data)
      pos = data.index('ANMF')
      pos != nil
    end
    def upload_image(file)
      # validate image format
      is_image_valid = is_image_valid(file)
      if is_image_valid[:error] != nil
        return {"error": is_image_valid[:error]}
      end
      
      # generate id for upload
      o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
      img_id = (0...50).map { o[rand(o.length)] }.join

      # write file
      img_name = "#{img_id}.#{is_image_valid[:type]}"
      File.open("public/uploads/#{img_name}", 'wb') { |file| file.write(is_image_valid[:data]) }

      image_link = root_url.to_s + "uploads/"+img_name
      return {"ok":image_link}
    end
    def slack_open_conversation(user)
      puts "opening convo with: " + user
      if ENV["SLACK_BOT_TOKEN"] == nil || ENV["SLACK_BOT_TOKEN"].blank?
        puts "error: no slack bot token set !!"
        return
      end
      url = URI("https://slack.com/api/conversations.open")
      body = { "users": user }
      headers = { 'Content-Type': 'application/json', "Authorization": "Bearer " + ENV["SLACK_BOT_TOKEN"]  }
      res = Net::HTTP.post(url, body.to_json, headers)
      puts res.body
      data = JSON.parse(res.body)
      return data["channel"]["id"]
    end
    def slack_send_message_conversation(dm_id,text)
      if ENV["SLACK_BOT_TOKEN"] == nil || ENV["SLACK_BOT_TOKEN"].blank?
        puts "error: no slack bot token set !!"
        return
      end
      url = URI("https://slack.com/api/chat.postMessage")
      body = { "channel": dm_id, "text":text }
      headers = { 'Content-Type': 'application/json', "Authorization": "Bearer " + ENV["SLACK_BOT_TOKEN"]  }
      res = Net::HTTP.post(url, body.to_json, headers)
      puts res.body
      data = JSON.parse(res.body)
    end
    def get_islands
      @islands = [6,12,26]
    end
    def generate_hackatime_text()
      p1 = ((@voyage != nil && @voyage.hackatime != nil && @voyage.hackatime != "") ? @voyage.hackatime : "Not linked" )
      p2 = " (" + ((@voyage != nil && @voyage.total_seconds != nil) ? (@voyage.total_seconds / 60 / 60).to_i.to_s : "") + "h)"
      
      @hackatime_text = p1+p2
    end
    def trim_length_fixed(t,l)
      if t.length > l
        t = t.slice(0,l-3)+"..."
      end
      t
    end
    def trim_length(t)
      trim_length_fixed(t,25)
    end
    def generate_desc_trimmed
      t = (@voyage != nil && @voyage.desc != nil) ? @voyage.desc : ""
      @voyage_desc_trim = trim_length(t)

      t = (@voyage != nil && @voyage.name != nil) ? @voyage.name : ""
      @voyage_name_trim = trim_length(t)

      t = (@voyage != nil && @voyage.repo != nil) ? @voyage.repo : ""
      @voyage_repo_trim = trim_length(t)
    end
    def get_next_island
      @next_island = 999
      @island_indx = 0
      last = 0
      if @voyage != nil
        last=@voyage.last_island
      end
      for island in @islands
        if island > last
          @next_island = island
          break
        end
        @island_indx += 1
      end
      @found_island = false
      @found_prices = []
      if @voyage != nil and @voyage.total_seconds >= @next_island * 60 * 60
        @found_island = true
        @found_prices = @prices[@island_indx]
      end
    end
    def get_prices
      @prices = [
        {
          "blahaj":{"name":"Blåhaj"},
          "pinecil":{"name":"Pinecil"},
          "pizero2w":{"name":"Pi Zero 2W"},
        },
      
        {
          "pico8":{"name":"Pico-8"},
          "pipico":{"name":"Pi Pico"},
          "cloudflare":{"name":"$12 Domain Grant"},
        },
      
        {
          "innioasis":{"name":"Innioasis Y1"},
          "tamagotchi":{"name":"Tamagotchi !!"},
          "cardputer":{"name":"Cardputer (Adv)"},
          "pinetime":{"name":"Pinetime"},
        },
      ]
    end
    def set_logged_in
      @loggedin = session[:user_id] != nil and session[:user_id]["uid"] != nil
      if @loggedin
        @user = User.find(session[:user_id]["id"])
        if @user.voyage != nil
          @voyage = Voyage.find(@user.voyage)
        end
      end
    end
    def ysws_start
      date = "2026-08-02T22:00:00.000Z"
      # TODO: REPLACE DATE BEFORE LAUNCH
      date = "2026-07-07T22:00:00.000Z"

      date
    end
    def require_logged_in
      set_logged_in
      if not @loggedin
        redirect_to root_path
      end
    end
    def get_hackatime_projects
      token = @user.token
      get_hackatime_projects_with_token(token)
      if @token_invalid
        @user.token = nil
        @user.save
      end
    end
    def get_hackatime_projects_with_token(token)
      if token == nil
        @projects = []
        return
      end

      url = URI("https://hackatime.hackclub.com/api/v1/authenticated/projects?include_archived=false&projects=&since=&until=&until_date=&start="+ysws_start+"&end=&start_date=&end_date=")
      req = Net::HTTP::Get.new(url)
      req["Authorization"] = "Bearer " + token
      res = Net::HTTP.start(url.hostname, url.port, use_ssl: url.scheme == "https") { |http|
        http.request(req)
      }
      @token_invalid = false
      if not (res.kind_of? Net::HTTPSuccess)
        @token_invalid = true
        @projects = []
        return
      end

      data = JSON.parse(res.body)
      @projects = data["projects"]
    end
end
