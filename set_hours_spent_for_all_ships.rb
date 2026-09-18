# script that retroactively sets the Hours Spent field in the airtable for all synced projects

# used because i didnt use to do set that field, but now realised i need to, and need to
# set for all previous projects too.

# should only ever be ran once to handle this migration.
# wont be needed in the future on anyone else than me.

for voyage in Voyage.all
    if voyage.ship_status == 2
        AirtableEntry.update(voyage.airtable_entry, {"Optional - Override Hours Spent":voyage.total_seconds / 60.0 / 60.0})
        puts "Updated #{voyage.name} - airtable id: #{voyage.airtable_entry})"
    end
end

