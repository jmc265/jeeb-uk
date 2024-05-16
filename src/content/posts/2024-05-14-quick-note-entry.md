---
title:  "Quick note entry (MacOSx & Android)"
permalink: quick-note-entry/
layout: post
tags:
  - note-taking
  - notes
  - daily
  - markdown
  - bash
  - automation
  - mac osx
  - android
  - raycast
  - tasker
---

I keep daily notes in a Markdown file, and I need to make sure I can add entries to those notes as quickly as possible in order to avoid disturbing the flow of the task I am working on.

---

I have therefore created a neat little tool on my laptop which let's me use a global shortcut, type the message and then get on with my day. I have set up something similar on my phone too.

## MacOSX

Using [Raycast](https://www.raycast.com/) we can add a global shortcut for a custom script. The script is a simple shell script which takes a parameter (the note's content), finds the correct file and appends the text adding in a timestamp:

```shell
current_date=$(date +%F)
current_time=$(date +%R)
echo -e "${current_time} - $1" >> notes/daily/${current_date}.md
```

Then it is a case of assigning this script to a global shortcut within Raycast (I have used `⌘ N`).

## Android

I also wanted to have a similar experience on my phone for notes-on-the-go. This one takes a bit more of a setup than with Raycast. For this I used [Tasker](https://tasker.joaoapps.com/) to add a 'Scene' which is then attached to a shortcut on my home screen. When I tap the shortcut, the scene launches, I tap in my note then press the "Done" button. The note (along with the timestamp) get added to the daily note in the exact same way. Here is the task:

![tasker view](/content/posts/assets/daily-note-tasker.png)
