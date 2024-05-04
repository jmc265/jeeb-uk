I keep daily notes in a Markdown file, and I need to make sure I can add entries to those notes as quckily as possible in order to avoid disturbing the flow of the task I am working on.

---

I have therefore created a neat little tool on my laptop which let's me use a global shortcut, type the message and then get on with my day. I have set up something similar on my phone too.

## MacOSX

Using [Raycast](https://www.raycast.com/) we can add a global shortcut for a custom script. The script is a simple shell script which takes a parameter (the note's content), finds the correct file and appends the text adding in a timestamp:

```shell
```

Then it is a case of assigning this script to a global shortcut within Raycast. I have used `+n`. 

## Android

I also wanted to have a similar experience on my phone for notes-on-the-go. This one takes a bit more of a setup than with Raycast. For this I used [Tasker](https://tasker.joaoapps.com/) to add a 'Scene' which is then attached to a shortcut on my home screen. 