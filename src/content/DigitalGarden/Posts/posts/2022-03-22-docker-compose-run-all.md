---
title:  "Run All Docker Compose stacks in sub-directories"
permalink: docker-compose-run-all/
layout: post
tags:
  - programming
  - docker
  - docker-compose
  - docker compose
---

For my home server, I have a number of `docker-compose.yml` files, one for each application I run, in a sub-directory. I wanted a way to automatically do a `docker-compose up -d` for all of the applications at once, so that I don't have to `cd` into each directory in turn. 

---

My directory structure is:

```
cwd
 | - app1
 |    | - docker-compose.yml
 | - app2
 |    | - docker-compose.yml
 |    | - .env
 | - .env
```

Unfortunately the docker-compose command doesn't allow specifying a glob pattern to run. So a small script should do the trick:

```shell
export COMPOSE_FILES="$(find . | grep "docker-compose.yml")"

for COMPOSE_FILE in $COMPOSE_FILES
do
    docker-compose -f $COMPOSE_FILE --env-file ./.env up -d --build
done
```

Running this script in the top level directory will now run all of my apps up at once.