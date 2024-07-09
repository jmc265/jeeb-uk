---
title:  "Crontab-as-code"
permalink: crontab-as-code/
layout: post
tags:
  - programming
  - linux
  - crontab
  - unix
---

There are [various](https://github.com/bdd/runitor) [tools](https://gitlab.science.ru.nl/bram/sch) [that](https://github.com/pforret/crontask) [either](https://github.com/dimo414/task-mon) wrap crontab, or offer alternatives to it. All I wanted though, was a simple solution to have my scheduled tasks defined as code (checked into a git repo) so that the tasks are reproducible and idempotent, just as Terraform is for IaaS.

---

All of my scheduled tasks are linked to services (running in docker containers), and I wanted my tasks defined alongside the service which they worked upon. Therefore, I have a directory structure as below:

```
cwd
 | - app1
 |    | - docker-compose.yml
 |    | - crontab
 | - app2
 |    | - docker-compose.yml
 |    | - crontab 
```

I then have a small script at the top-level which combines all of the individual crontab files and applies the resultant set to the system crontab:

```shell
#!/bin/bash

export CRONTAB_FILES="$(find . | grep "crontab")"

# Re-create all Crontab
echo "# Do not edit this file, it is autogenerated" > tmp_crontab
for CRONTAB_FILE in $CRONTAB_FILES
do
    echo "# From $CRONTAB_FILE:" >> tmp_crontab
    cat $CRONTAB_FILE >> tmp_crontab
    printf "\n" >> tmp_crontab
done

crontab tmp_crontab
rm tmp_crontab
crontab -l
```

Running this script means that the crontab on my server is now defined as code and checked into my git repo allowing the tasks to be reproducible.