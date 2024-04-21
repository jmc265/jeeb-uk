---
title:  "Using Application Passwords with Wordpress Docker" 
permalink: wordpress-application-password/
layout: post
tags:
  - programming
  - wordpress
  - php
  - docker
---

I want to be able to use [Application Passwords](https://developer.wordpress.org/rest-api/using-the-rest-api/authentication/#basic-authentication-with-application-passwords) with my local network Wordpress installation that was using the official Docker image. There doesn't seem to be a huge amount online about how to do this so I thought I would post the solution that worked for me:

---

As I am not using https (because the service is only exposed internally within my network), I need to set an environment variable called `WP_ENVIRONMENT_TYPE` within Wordpress to "local". I can do this from my docker compose file using the `WORDPRESS_CONFIG_EXTRA` variable:

```yaml
services:
  wordpress:
    image: wordpress
    environment:
      WORDPRESS_DB_HOST: wordpress-db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: ${SQL_PASSWORD}
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_ENVIRONMENT_TYPE', 'local');
    volumes:
      - ${DOCKER_APP_DATA}/wordpress/html:/var/www/html
```

Once this is done, you can navigate to your to the user admin part of wp-admin and edit a user. At the bottom of the page you can now create Application Passwords for that user.