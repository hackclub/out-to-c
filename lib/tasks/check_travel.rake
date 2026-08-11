# lib/tasks/delete_pdfs.rake
namespace :travel do
  desc "Check all user's hackatime project travel distance to see if theyve reached new island."
  task check: :environment do
    ApplicationController.load_lib
    islands = return_islands
    for user in User.all
        if user.voyage == nil
            next
        end
        voyage = Voyage.find(user.voyage)
        if voyage == nil
            next
        end
        s = false
        if voyage.last_island_dm == nil
            voyage.last_island_dm = 0
            s = true
        end
        projects = get_hackatime_projects_with_token(user.token)[:projects]
        
        time = voyage.total_seconds
        for a in projects
            if a["name"] == voyage.hackatime
                time = a["total_seconds"]
                break
            end
        end
        
        next_island = 999
        island_indx = 0
        last = 0
        if voyage != nil
            last=voyage.last_island
        end
        for island in islands
            if island > last
                next_island = island
                break
            end
            island_indx += 1
        end

        if voyage.total_seconds >= next_island * 60 * 60
            if next_island > voyage.last_island_dm
                mid = slack_open_conversation(user.uid)
                slack_send_message_conversation(mid, "Captain! We found an island, and even better, there's treasure! :woa::treasure-box:\n\nYou should go check it out ASAP!\n\n/pirate orph'")
                voyage.last_island_dm = next_island
                s = true
            end
        end
        
        if s
            voyage.save!
        end
    end
  end
end