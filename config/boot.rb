ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

require "dotenv"
require "airrecord"

Dotenv.load

Airrecord.api_key = ENV["AIRTABLE_API_TOKEN"]

class AirtableEntry < Airrecord::Table
  self.base_key = ENV["AIRTABLE_BASE_ID"]
  self.table_name = "YSWS Project Submission"
end