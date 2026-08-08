# Out to C (backend server)

This is the Ruby on Rails backend for the Hack Club YSWS [Out to C](https://out-to-c.dino.icu/)!

## Running locally
* Install Ruby on Rails (good luck).
* Clone this repo and CD there
* Use `bundle install`
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