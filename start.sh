#!/bin/sh

set -e

# Gera config/storage.yml dinamicamente se não existir
if [ ! -f config/storage.yml ]; then
  mkdir -p config
  cat <<EOF > config/storage.yml
s3:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: <%= ENV['AWS_REGION'] %>
  bucket: <%= ENV['S3_BUCKET_NAME'] %>
  endpoint: <%= ENV['S3_ENDPOINT'] %>
  force_path_style: true

local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
EOF
fi

echo Waiting for database...

while ! pg_isready -h ${PGHOST} -p ${PGPORT}; do sleep 0.25; done; 

echo Database is now available

bundle exec rails db:chatwoot_prepare

bundle exec rails db:migrate

multirun \
    "bundle exec sidekiq -C config/sidekiq.yml" \
    "bundle exec rails s -b 0.0.0.0 -p $PORT"

false
