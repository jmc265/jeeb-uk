Crontab (`/etc/crontab`) structure:
```shell
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
```
Note that after the timings, a username just be specified as that file is not user-specific
If you do `crontab -e` you will be editing a crontab just for your current user and therefore don't specify a username before the command

## Timings
```shell
0 * * * * command # Run command every hour
*/5 * * * * command # Run command every 5 mins
*/30 * * * * command # Run command every 30 mins
```

## My Blog Posts
- [Crontab-as-code](../posts/crontab-as-code)

## Links
https://crontab.guru/