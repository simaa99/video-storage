#!/bin/bash

# High-Quality HLS Conversion Script
# Usage: ./convert_hls.sh input.mp4 output_dir_name
# Example: ./convert_hls.sh CHARACTER.mp4 character

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <input_file> <output_dir_name>"
  exit 1
fi

INPUT_FILE=$1
OUTPUT_DIR="hls/history/$2"

# Create directories
mkdir -p "$OUTPUT_DIR/v0"
mkdir -p "$OUTPUT_DIR/v1"

echo "Processing $INPUT_FILE into $OUTPUT_DIR (High Quality)..."

# V0 - 1080p (High Quality)
# CRF 18: Visually very close to lossless. 
# slow preset: Max compression efficiency for the target quality.
ffmpeg -y -i "$INPUT_FILE" \
  -vf "scale=trunc(oh*a/2)*2:1080" \
  -c:v libx264 -crf 18 -preset slow \
  -c:a aac -b:a 256k -ac 2 \
  -hls_time 8 -hls_playlist_type vod \
  -hls_segment_filename "$OUTPUT_DIR/v0/seg%03d.ts" \
  "$OUTPUT_DIR/v0/index.m3u8"

# V1 - 750p (Medium Quality)
# CRF 21: Excellent quality with more compact file size.
ffmpeg -y -i "$INPUT_FILE" \
  -vf "scale=trunc(oh*a/2)*2:750" \
  -c:v libx264 -crf 21 -preset slow \
  -c:a aac -b:a 128k -ac 2 \
  -hls_time 8 -hls_playlist_type vod \
  -hls_segment_filename "$OUTPUT_DIR/v1/seg%03d.ts" \
  "$OUTPUT_DIR/v1/index.m3u8"

# Get resolutions for master playlist
V0_RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$OUTPUT_DIR/v0/seg000.ts" | head -n 1 | tr -d '\r\n')
V1_RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$OUTPUT_DIR/v1/seg000.ts" | head -n 1 | tr -d '\r\n')

# Create Master Playlist
cat <<EOF > "$OUTPUT_DIR/master.m3u8"
#EXTM3U
#EXT-X-VERSION:6
#EXT-X-STREAM-INF:BANDWIDTH=3500000,RESOLUTION=$V0_RES,CODECS="avc1.640028,mp4a.40.2"
v0/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1800000,RESOLUTION=$V1_RES,CODECS="avc1.64001f,mp4a.40.2"
v1/index.m3u8
EOF

echo "Done: $OUTPUT_DIR"
