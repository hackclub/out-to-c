# script that retroactively sets the has_been_shipped property of all shipped voyages

# should only ever be ran once to handle this migration.
# wont be needed in the future on anyone else than me.

for v in Voyage.all
    if v.ship_status != 0
        v.has_been_shipped = true
        v.save
    end
end