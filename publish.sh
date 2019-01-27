#!/bin/bash -e

source regions.sh

MD5SUM=$(md5 -q php73.zip)
S3KEY="php73/${MD5SUM}"

for region in "${PHP_REGIONS[@]}"; do
  bucket_name="com-fazland-php-lambda-${region}"

  echo "Publishing Lambda Layer php73 in region ${region}..."
  # Must use --cli-input-json so AWS CLI doesn't attempt to fetch license URL
  version=$(aws --profile=alessandro.chitolina --region $region lambda publish-layer-version --cli-input-json "{\"LayerName\": \"php73\",\"Description\": \"PHP 7.3 Lambda Runtime\",\"Content\": {\"S3Bucket\": \"${bucket_name}\",\"S3Key\": \"${S3KEY}\"},\"CompatibleRuntimes\": [\"provided\"],\"LicenseInfo\": \"http://www.php.net/license/3_01.txt\"}" --output text --query Version)
  echo "Published Lambda Layer php73 in region ${region} version ${version}"

  echo "Setting public permissions on Lambda Layer php73 version ${version} in region ${region}..."
  aws --profile=alessandro.chitolina --region $region lambda add-layer-version-permission --layer-name php73 --version-number $version --statement-id=public --action lambda:GetLayerVersion --principal '*' > /dev/null
  echo "Public permissions set on Lambda Layer php73 version ${version} in region ${region}"
done
