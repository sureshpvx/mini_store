#!/usr/bin/env bash
set -o errexit

bundle install
bin/rails tailwindcss:build
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
bundle exec rails search:setup