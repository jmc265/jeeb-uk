---
title: "Raspberry Pi bedside Lamp with Spotify and NodeRed"
permalink: rpi-bedside-lamp-spotify/
layout: post
tags:
  - projects
  - rpi
  - Raspberry Pi
  - nodered
  - mqtt
---

Because why wouldn't you want an MQTT controlled, automated lamp with the ability to play music? I can see I don't need to sell you on this idea any more, so let's get right in with what you need:

---

## Requirements

* [Mood Light - Pi Zero W kit](https://shop.pimoroni.com/products/mood-light-pi-zero-w-project-kit) & an SD card
* Mini USB powered speakers (I used [this one](https://www.amazon.co.uk/dp/B006RBSHAQ/ref=cm_sw_em_r_mt_dp_U_tTp-EbF2S46NS]))

## Raspberry Pi Setup

Setup the Mood Light as per the instructions.

For the OS choice, you can use pretty much any distribution you want, however I would personally recommend [DietPi](https://dietpi.com/). It has easy installers for the software items below.

As we are using a USB speaker, there are some additional steps you will need to do to make sure that it is the default output for the Pi. I found [this article](https://www.raspberrypi-spy.co.uk/2019/06/using-a-usb-audio-device-with-the-raspberry-pi/) very helpful.

## Software

If you use DietPi, the below will be easy to install through the `dietpi-software` tool.

* [Mopidy](https://mopidy.com) will be used to play music through the speaker
* [Mopidy Spotify Extension](https://mopidy.com/ext/spotify/) if you want to use Spotify. Other streaming sources available!
* [NodeRed](https://nodered.org/) will be used to automate the lights and music
* [node-red-contrib-mopidy](https://flows.nodered.org/node/node-red-contrib-mopidy) for a link between NodeRed and Mopidy
* [node-red-node-pi-unicorn-hat](https://flows.nodered.org/node/node-red-node-pi-unicorn-hat) for a link between NodeRed and the lights in the Mood Light
* [MQTT](http://mqtt.org/) will be used to remote control the lamp

Make sure the above are all installed and if you are using Spotify, have that setup as well.

## The Automations

Let's deal with turning on the light first. We will setup an automation that looks like the below:

![Lamp Automation](/content/posts/assets/bedside-light/lamp-automation.png)

Let's walk through that from right to left.

The right-most node is the node from [node-red-node-pi-unicorn-hat](https://flows.nodered.org/node/node-red-node-pi-unicorn-hat). The defaults config for this node should set the brightness to 0%.

The 2 functions set the brightness to 100% brightness:

```javascript
return {
    payload: `brightness,100`
};
```

And set the lamp to a nice yellowish colour:

```javascript
return {
    payload: `255,198,36`
};
```

The left-most node is a simple inject which triggers at 22:00 every day of the week.

Next let's add some some nodes to start playing some music at the same time:

![Music Automation](/content/posts/assets/bedside-light/music-automation.png)

We have a list of nodes that effect Mopidy:

1. `tracklist.clear` - Remove all the previous tracks in the list in Mopidy
1. `mixer.setvolume` - I have set this to 10%, but you will need to choose a value best for you
1. `tracklist.add` - This is where you can choose which tracks to play. I have set the `uris` value to [`["spotify:playlist:37i9dQZF1DX9uKNf5jGX6m"]`](https://open.spotify.com/playlist/37i9dQZF1DX9uKNf5jGX6m)
1. `playback.play` - Play the tracks!

I have added a delay for the `add` and `play` nodes so that we know that the tracklist has been cleared first and the volume set correctly. 

### Turning off the light

Now that we have turned on the light, we need to turn it off when we want to sleep. We are going to fade out the light for added shazam and continue to play the music for 30 minutes before turning it off. We could do this at a preset time like so:

![Turnoff Automation](/content/posts/assets/bedside-light/turnoff-automation.png)

The `Fade Down Values` function outputs an array of values counting down from 100% to 0% in increments of 5:

```javascript
const startBrightness = 100;
const endBrightness = 0;
const payload = [];
for (let i = startBrightness; i >= 0; i-=5) {
    payload.push(i);
}
return {
    payload
};
```

The delay then makes makes sure that each 5% decrement is done once every 1 second.

The bottom part simply waits 30 minutes then pauses the playback.

But that isn't quite good enough. We might want to turn off the lamp before or after a set time.

### Remote Control

We will be using MQTT and an Android App called [IoT MQTT Panel](https://play.google.com/store/apps/details?id=snr.lab.iotmqttpanel.prod&hl=en_GB) to turn off the lamp when we are ready. 

So first we need to add an MQTT node and replace the timing injection node:

![Turnoff Remote Control](/content/posts/assets/bedside-light/turnoff-remote.png)

And then in IoT MQTT Panel we can set up some controls for the lamp:

![iotmqttpanel](/content/posts/assets/bedside-light/iotmqttpanel.jpg)

The button with the bed on it publishes to the `home/sleep` topic. And there are a few other controls in there for manually setting the lamp's colour and brightness. Here is what the nodes look like for dealing with brightness and colour topics:

![MQTT Controls](/content/posts/assets/bedside-light/mqtt-controls.png)

### Conclusion

And we are done! The light and music will start at 22:00 every day. The light will fade out when you click the button in the Android App and the music will stop 30 minutes later. The whole flow can be [found here](/content/posts/assets/bedside-light/flows.json).

I have some thoughts on how to extend this:

* (Easy) The music could be faded out rather than abruptly stop
* (Average) The setup could be used as an alarm clock with the light and music slowly fading up at a specified time
* (Hard) A physical button would be better than using an Android App for turning off the light. Unfortunately there are no GPIO pins we can use. Potentially we could use a USB hub to connect the speaker and some other input.