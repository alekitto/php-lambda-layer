#!/bin/bash -e

VERSION=$1

source regions.sh

MD5SUM=$(md5 -q php73.zip)
S3KEY="php73/${MD5SUM}"

for region in "${PHP_REGIONS[@]}"; do
  bucket_name="com-fazland-php-lambda-${region}"

  echo "Deleting Lambda Layer php version ${VERSION} in region ${region}..."
  aws --profile=alessandro.chitolina --region $region lambda delete-layer-version --layer-name php73 --version-number $VERSION > /dev/null
  echo "Deleted Lambda Layer php version ${VERSION} in region ${region}"
done
