#!/usr/bin/env bash
set -o errexit

bundle install

bundle exec rails assets:precompile
bundle exec rails assets:clean

bundle exec rails db:migrate
bundle exec rails search:setup  # safe to run every time, only rebuilds if empty