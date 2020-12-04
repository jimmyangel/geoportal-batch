#!/bin/bash
# exit on error
set -e

source ./config.sh

baseurl="https://$BUCKET.s3-$REGION.amazonaws.com"

# Create color table file
echo $2 | sed "s/:/: /g" | tr "-" "\n" > color.txt

# Get source file
filename=$1
echo "$baseurl/files/$filename"
curl -s -O $baseurl/files/$filename
name=${filename%.*}
namelc="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
echo "derived name: $namelc"

# Generate tiles
echo "create virtual raster with colors"
if [ $3 = "exact" ]; then EXACT="-exact_color_entry"; else EXACT=""; fi

gdaldem color-relief -alpha $EXACT -of vrt $filename color.txt temp.vrt

echo "generate raster tiles"
gdal2tiles.py --profile=mercator -q -z 4-10 temp.vrt rtiles/$namelc
echo -e "\n"

# Copy tiles to S3
echo "remove old tiles from rtiles/$namelc"
aws s3 rm s3://$BUCKET --quiet --recursive --exclude "*" --include "rtiles/$namelc/*"
echo "upload generated tiles to rtiles/$namelc"
aws s3 cp rtiles s3://$BUCKET/rtiles --acl "public-read" --only-show-errors --recursive
echo "finished processing"
