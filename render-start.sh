#!/usr/bin/env bash
set -o errexit

bundle exec sidekiq -C config/sidekiq.yml &
bundle exec puma -C config/puma.rb -p ${PORT:-3000}