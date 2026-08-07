#!/usr/bin/env bash

git pull
npx esbuild --bundle app/assets/javascript/main.js --format=esm --minify > app/assets/javascript/min.js
RAILS_ENV=production rails assets:precompile
