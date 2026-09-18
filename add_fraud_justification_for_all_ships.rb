# script that retroactively updates the Additional Justification field in the airtable for all fraud approved projects 
# with details about who fraud approved it

# used because i didnt use to do include that info, but now realised i need to, and need to
# set for all previous projects too.

# should only ever be ran once to handle this migration.
# wont be needed in the future on anyone else than me.

for voyage in Voyage.all
    if voyage.ship_status == 2 && voyage.fraud_approved
        approver = User.where(:uid => voyage.fraud_approved_by).first()
        approved_justification = "\nFraud Approved by #{approver.name} (@#{approver.uid})"
        if not (voyage.additional_justification.include? approved_justification)
            voyage.additional_justification = voyage.additional_justification + approved_justification
            AirtableEntry.update(voyage.airtable_entry, {"Justification - Additional Justification":voyage.additional_justification})
            voyage.save!
            puts "Updated #{voyage.name}. New justifcation: #{voyage.additional_justification.inspect}"
        else
            puts "Skipped updating #{voyage.name}."
        end
    end
end

