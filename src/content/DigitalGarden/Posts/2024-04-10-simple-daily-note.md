---
title:  "Simple Daily Notes" 
permalink: simple-daily-notes/
layout: post
draft: true
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

I am sure that looks lovely when rendered within Obsidian, but now that I just use VSCode on my computer and Markor in my phone, it means nothing.


```shell
#!/bin/bash

current_date=$(date +%F)
yesterday_date=$(date +%F -d "yesterday")

yesterday_todo=$(sed -n '/## Todo/,/##/{/## Todo/b;/##/b;p}' ../00\ -\ Daily\ 📅/${yesterday_date}.md)


cat ./snippets/Daily\ Note.md >> ../00\ -\ Daily\ 📅/${current_date}.md
awk -i inplace -v input="$yesterday_todo" 'NR == 1, /insert-here/ { sub(/insert-here/, input) } 1' ../00\ -\ Daily\ 📅/${current_date}.md
```

```markdown
# 📓
## Todo
insert-here

## What did you do today?
```