#!/bin/bash

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

echo "Processing $INPUT_FILE into $OUTPUT_DIR..."

# V0 - 720p (Vertical: 406x720 approx)
ffmpeg -y -i "$INPUT_FILE" \
  -vf "scale=trunc(oh*a/2)*2:720" \
  -c:v libx264 -crf 23 -preset fast \
  -c:a aac -b:a 128k -ac 2 \
  -hls_time 8 -hls_playlist_type vod \
  -hls_segment_filename "$OUTPUT_DIR/v0/seg%03d.ts" \
  "$OUTPUT_DIR/v0/index.m3u8"

# V1 - 360p (Vertical: 202x360 approx)
ffmpeg -y -i "$INPUT_FILE" \
  -vf "scale=trunc(oh*a/2)*2:360" \
  -c:v libx264 -crf 28 -preset fast \
  -c:a aac -b:a 64k -ac 2 \
  -hls_time 8 -hls_playlist_type vod \
  -hls_segment_filename "$OUTPUT_DIR/v1/seg%03d.ts" \
  "$OUTPUT_DIR/v1/index.m3u8"

# Get resolutions for master playlist
V0_RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$OUTPUT_DIR/v0/seg000.ts" || echo "406x720")
V1_RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$OUTPUT_DIR/v1/seg000.ts" || echo "202x360")

# Create Master Playlist
cat <<EOF > "$OUTPUT_DIR/master.m3u8"
#EXTM3U
#EXT-X-VERSION:6
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=$V0_RES,CODECS="avc1.64001e,mp4a.40.2"
v0/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=640000,RESOLUTION=$V1_RES,CODECS="avc1.64000d,mp4a.40.2"
v1/index.m3u8
EOF

echo "Done: $OUTPUT_DIR"
