---
title:  "Simple Daily Notes" 
permalink: simple-daily-notes/
layout: post
tags: 
  - posts
  - note-taking
  - notes
  - daily
  - markdown
  - bash
  - automation
---
It is very popular at the moment in some circles online to show off one's personal note-taking process/system. This generally revolves around [Obsidian](https://obsidian.md/) and a very convoluted set of plugins and/or templates. 
---

And I was one of those people. I bought fully into Obsidian and its ecosystem of plugins and community. I had a complicated setup that did all sort of automation for me, and did various bits of post processing on the markdown files. But I have moved away from that and onto something much simpler. And I have done that for 2 reasons:

1. The complexity is tiring. Setting everything up is time consuming. Making sure all the plugins are up-to-date and don't break as time goes on is tiring and tedious (remember, we want to keep taking these notes for many many years). It is all just a bit unnecessary when all we need to do is take some text-based notes each day.
1. The plugins/automations are not portable. What I mean by that is that once you start using the plugins and various Obsidian-specific syntax in your Markdown files, you are locked into that application. If I look back at my notes, I have months and months of this:

````markdown
### Outstanding tasks
```tasks
not done
hide backlink
sort by description
```
## What did you do today?
```tasks
done on 2022-04-27
hide backlink
hide edit button
```
````

I am sure that looks lovely when rendered within Obsidian, but now that I just use VSCode on my computer and Markor on my phone, it means nothing. The information has been lost; locked within Obsidian.

## Simple Daily Notes

So let's make something that is simple, automated and has no vendor lock in. First, we will start with a template for a Markdown file that we will want created every day for us to use: 

> `snippets/daily-note.md`
```markdown
# 📓
## Todo
- 

## What did you do today?
- 
```

And then create a cron job and shell script which creates this file at the start of each day:

```shell
# Cronjob: 
1 0 * * * make-daily-note.sh

# make-daily-note.sh
current_date=$(date +%F)
cat snippets/daily-note.md >> daily/${current_date}.md
```

Then every day, we get a brand new empty file that we can use for the day's notes. 

There is one additional feature that I wanted, which is for the contents underneath the `## Todo` heading to be copied from one day to the next. This way, my incomplete ToDos follow me through the days until they are completed. With a small change to our template and little bit of `sed` we can accomplish that:

> `snippets/daily-note.md`
```markdown
# 📓
## Todo
<-- Insert ToDos Here -->
```

> `make-daily-note.sh`
```shell
current_date=$(date +%F)
yesterday_date=$(date +%F -d "yesterday")

yesterday_todo=$(sed -n '/## Todo/,/##/{/## Todo/b;/##/b;p}' daily/${yesterday_date}.md)

cat snippets/daily-note.md >> daily/${current_date}.md
awk -i inplace -v input="$yesterday_todo" 'NR == 1, /<-- Insert ToDos Here -->/ { sub(/<-- Insert ToDos Here -->/, input) } 1' daily/${current_date}.md
```