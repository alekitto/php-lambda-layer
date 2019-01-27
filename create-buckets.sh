#!/bin/bash -e

source regions.sh

for region in "${PHP_REGIONS[@]}"; do
  bucket_name="com-fazland-php-lambda-${region}"

  echo "Creating bucket ${bucket_name}..."

  aws s3 mb s3://$bucket_name --region $region  --profile=alessandro.chitolina
done
