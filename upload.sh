#!/bin/bash -e

source regions.sh

MD5SUM=$(md5 -q php73.zip)
S3KEY="php73/${MD5SUM}"

for region in "${PHP_REGIONS[@]}"; do
  bucket_name="com-fazland-php-lambda-${region}"

  echo "Uploading php73.zip to s3://${bucket_name}/${S3KEY}"

  aws --region $region s3 cp php73.zip "s3://${bucket_name}/${S3KEY}"
done
