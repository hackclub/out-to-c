# Out to C

<img src="public/banner.png" width=500>

This is the Ruby on Rails server for [Out to C](https://out-to-c.hackclub.com/)!

Hosted on Orchard.

## Features

* Hack Club Auth Login
* Hackatime linking
* Local Postgresql database for projects and user accounts
    * Seperate remote airtable database for PII, with only write access
* Project infrastructure
    * Live Slack DM updates when you reach a new island
    * Shipping!
* Docs page
* Onboarding tutorial
* Reviewer panel
    * When a project is shipped, a notfication is sent out on slack to reviewers.
    * Upon approval/rejection, the user is notified, along with a note from the reviewer.
    * Upon approvals, the user is notified and also receives a feedback form. An admin is also notified about fulfilment.
* Admin panel

## Running locally
* Install Ruby on Rails (good luck).
* Clone this repo and CD there
* Use `bundle install`
* Setup postgres (follow [this](https://mangohost.net/blog/how-to-set-up-ruby-on-rails-with-postgres/) guide)
* Do `rails db:create db:migrate` to set up the database.
* Set up the .env file! Copy the example file with `cp .env.example .env`, then open .env and follow the instructions there.
* And then you can run the server with `rails s` and hope it works!!

### Slack Bot
The backend uses a slack bot for fetching user information and sending messages!

The server will work for development purposes without a bot, but for production one is needed.

You'll have to create a bot with the following scopes:
```
channels:read
chat:write
channel:history
groups:history
groups:read
im:history
im:read
im:write
mpim:read
users.profile:read
users:read
```

## Running in production
For production, a minified version of the JS needs to be built.
* Make sure Node.js and npm are installed, then run `npm install three esbuild`
* Then, to build the minified js code, run `npx esbuild --bundle app/assets/javascript/main.js --format=esm --minify > app/assets/javascript/min.js`
