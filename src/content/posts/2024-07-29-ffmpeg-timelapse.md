---
title:  "Using ffmpeg to capture a timelapse"
permalink: ffmpeg-timelapse/
layout: post
tags:
  - ffmpeg
  - bash
  - shell
  - programming
  - camera
  - stream
  - timelapse
---

I recently needed to capture a 24 hour timelapse video of my back garden in order to plot the sun and resulting shade throughout the day in order to inform a decision on how best to landscape the garden.

---

So I zip-tied an external camera I had lying around to the railing on my balcony, pointed it in just the right way and waited for a sunny day (surprising more difficult that expected at the end of the July).

I had a bash script waiting which would take photos every 60 seconds and store them in sequential jpg in a folder. Then, when I interrupted that process another ffmpeg command would stich all the photos together at 30fps to make a lovely little video.

```shell
#!/bin/bash

RTSP_URL="rtsp://USERNAME:PASSWORD@192.168.1.9/stream1"
OUTPUT_DIR="timelapse_images"
OUTPUT_VIDEO="timelapse.mp4"
FRAME_RATE=30
INTERVAL=60

# Create the output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Capture images every 60 seconds
ffmpeg -i "$RTSP_URL" -vf fps=1/$INTERVAL -q:v 1 $OUTPUT_DIR/output%04d.jpg

# Combine images into a timelapse video
ffmpeg -r $FRAME_RATE -f image2 -i $OUTPUT_DIR/output%04d.jpg -vcodec libx264 -crf 25 -pix_fmt yuv420p $OUTPUT_VIDEO
```