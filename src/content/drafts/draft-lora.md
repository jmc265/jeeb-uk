---
title:  "LoRA" 
permalink: lora/
layout: post
draft: true 
tags:
  - programming
  - stable diffusion
  - sdxl
  - lora
  - training
  - generative artificial intelligence
  - Automatic1111
  - Koya_ss
---

I wanted to learn about the new wave of "AI" image generation, particularly Stable Diffusion and how to create a LoRA (low-ranking adaptation) which would allow me to add training data to the model. I thought an excellent approach to this would be to train a LoRA based on my face in order to generate a professional looking headshot of myself for use on LinkedIn etc.

## Training Data

First, I needed a bunch of cropped images of my face. I have been self-hosting [PhotoPrism](https://www.photoprism.app/) for the past few years and one of the features that the software has inbuilt is facial recognition. Poking around in the PhotoPrism DB, I found a table called `markers`:

```
MariaDB [photoprism]> describe markers;
+-----------------+----------------+------+-----+---------+-------+
| Field           | Type           | Null | Key | Default | Extra |
+-----------------+----------------+------+-----+---------+-------+
| marker_uid      | varbinary(42)  | NO   | PRI | NULL    |       |
| file_uid        | varbinary(42)  | YES  | MUL |         |       |
| subj_uid        | varbinary(42)  | YES  | MUL | NULL    |       |
| x               | float          | YES  |     | NULL    |       |
| y               | float          | YES  |     | NULL    |       |
| w               | float          | YES  |     | NULL    |       |
| h               | float          | YES  |     | NULL    |       |
| q               | int(11)        | YES  |     | NULL    |       |
...
+-----------------+----------------+------+-----+---------+-------+
```

This had a foreign key to a table `subjects` which had a row for myself and another key to the `files` table which identifies the file where the "marker" (my face) was found. So a couple of joins later:

```
MariaDB [photoprism]> SELECT f.file_name, m.x, m.y, m.w, m.h from files f JOIN markers m ON f.file_uid = m.file_uid JOIN subjects s ON m.subj_uid = s.subj_uid WHERE s.subj_name = 'James';
+---------------------------------------------+----------+----------+-----------+-----------+
| file_name                               | x        | y        | w         | h         |
+-----------------------------------------+----------+----------+-----------+-----------+
| photos/2008/Uni/2008-05-31_21.00.59.jpg |   0.3875 | 0.272727 |  0.180469 |  0.269231 |
| photos/2008/Uni/2008-05-31_21.01.00.jpg | 0.407031 | 0.278555 |  0.182031 |  0.271562 |
| photos/2008/Uni/2008-05-31_21.34.04.jpg | 0.226562 | 0.300699 | 0.0765625 |  0.114219 |
| photos/2008/Uni/2008-05-31_21.35.03.jpg | 0.301562 | 0.334499 |      0.05 | 0.0745921 |
| photos/2008/Uni/2008-05-31_22.00.59.jpg |   0.3875 | 0.287048 |  0.166406 |  0.248541 |
...
+-----------------------------------------+----------+----------+-----------+-----------+
```

And we have the file name and location within image of my face!

So I wrote a script to automate the process of pulling out all of the images that contained me within them, and copy them to a new folder for training purposes:

```javascript
const { execSync } = require("child_process");
const fs = require('fs');
const path = require('path');

const SQL_PASSWORD = process.env.SQL_PASSWORD;
const DOCKER_APP_DATA = process.env.DOCKER_APP_DATA;
const PHOTO_BASE_DIR = `${process.env.PRIMARY_STORAGE}/media/home`;
const PHOTO_SIDECAR_BASE_DIR = `${DOCKER_APP_DATA}/photoprism/sidecar/photos`;

function getData() {
    const sql = `SELECT f.file_name, m.x, m.y, m.w, m.h from files f JOIN markers m ON f.file_uid = m.file_uid JOIN subjects s ON m.subj_uid = s.subj_uid WHERE s.subj_name = 'James';`;
    const dockerCommand = `docker exec mariadb mariadb --user root -p${SQL_PASSWORD} -D photoprism -N -t -e "${sql}"`;
    const cmdResponse = execSync(dockerCommand);
    const sqlResponse = cmdResponse.toString();

    return sqlResponse.split("\n")
        .filter(line => !line.startsWith("+--"))
        .map(line => {
            const parts = line.split('|');
            if (parts.length !== 7) {
                return null;
            }
            return {
                file: path.parse(parts[1].trim().replace('photos/', '')),
                x: Number(parts[2].trim()),
                y: Number(parts[3].trim()),
                w: Number(parts[4].trim()),
                h: Number(parts[5].trim())
            }
        })
        .filter(Boolean);
}

function copyImage(data) {
    console.log(`Copy Image ${JSON.stringify(data)}`);
    const originalFilePath = `${PHOTO_BASE_DIR}/${data.file.dir}/${data.file.base}`;
    const sidecarFilePath = `${PHOTO_SIDECAR_BASE_DIR}/${data.file.dir}/${data.file.base}`;
    const outputFilePath = `./james-photos/${data.file.name}${data.file.ext}`;

    let importFile;
    if (fs.existsSync(originalFilePath)) {
        importFile = originalFilePath;
    } else if (fs.existsSync(sidecarFilePath)) {
        importFile = sidecarFilePath;
    } else {
        return null;
    }

    try {
        execSync(`cp ${importFile} ${outputFilePath}`)
    } catch (e) {
        console.warn(`Error copying ${importFile}`);
    }
}

const data = getData();
for (const d of data) {
    copyImage(d);
}
```

### Cropping

Now that I have this data, I need to crop down each image to only show my face. We can see that the above data for `x`, `y`, `w` and `h` are all floats between 0 and 1, and I took a guess that these were percentages within the context of the resolution of the image. So for instance, on the first row above, my face would appear 38.75% from the left size of the image (`x`), 27.2727% from the bottom (`y`) and would have a width equal to 18.0469% of the width of the total image (`w`) and 26.9231% of the height (`h`).

I needed to write a script to go through all this data, as I had almost 1100 images here! I chose [ImageMagick](https://imagemagick.org) as the tool to do the actual cropping of the image. Let's construct a command for ImageMagick to do a crop for the row we looked at above:

```shell
convert 'photos/2008/Uni/2008-05-31_21.00.59.jpg' -auto-orient -set page "-%[fx:w*0.3875]-%[fx:h*0.272727]" -crop 18.0469%x26.9231%+0+0 './2008-05-31_21.00.59-cropped.jpg'
```

There's a lot there so let's unpack it:

* `'photos/2008/Uni/2008-05-31_21.00.59.jpg'` --> Input file location
* `-auto-orient` --> [Orients the image](https://imagemagick.org/script/command-line-options.php#auto-orient) using the EXIF data
* `-set page "-%[fx:w*0.3875]-%[fx:h*0.272727]"` --> Sets the images bottom x and y to be the location of the bottom x and y of my face
* `-crop 18.0469%x26.9231%+0+0` --> Crops the image by the percentages noted in the DB
* `'./2008-05-31_21.00.59-cropped.jpg'` --> Output file location

We run this command and end up with a very young-looking cropped photo of my face from 2008!

The last step here is to simply wrap this up in a small Javascript app and let it run over every entry in the the DB. The result is a lot of images of my face:

```shell
╭─  /mnt/primary/workspace/LoRA 
╰─ ls face | wc -l
1098
```

## Attempt 1

For my first attempt I choose only 12 of the 1100 images available to me in the hopes that it would provide a fast (if inaccurate) model which would allow me to determine if this process was going to work at all for what I wanted it for. The 12 I chose were all from my wedding photos, taken by a professional photographer and of very high quality.

I used these 12 images, along with the regularization images found on [github.com/tobecwb/stable-diffusion-regularization-images](https://github.com/tobecwb/stable-diffusion-regularization-images/tree/main/sdxl). Using an RTX 4090 rented from [runpod](https://www.runpod.io) I ran the images through the training process. Each epoch would take about 15 minutes, which seemed really fast. I stopped the process after 3 epochs and took a look at the results. And they weren't bad, for a first attempt at least. The output did vaguely look like me at times. But we could certainly do better than that.

## Attempt 2

So in my next attempt, I tried to give the learning process all 1100 images. I quickly cancelled it after it showed that it would take 300 hours per epoch (would would cost more than $100 on runpod!). I clearly needed to alter my process a little bit and understand what was taking the time before I launched that my photos at it again.

## Attempt 3

For an estimate on timings I gave it all 87 of my wedding photos which would take 16 hours per epoch. Still a very long time, especially if I wanted to let this run for all 10 epochs that I had originally intended.

I looked around the web for some guidance and found a few pages that I took various bits of advice from:

* https://aituts.com/sdxl-lora/
* https://rentry.org/59xed3#number-of-steps
* https://medium.com/@yushantripleseven/dreambooth-sdxl-using-kohya-ss-on-vast-ai-10e1bfa26eed

## Attempt 4

Based off of the above recommendations, I decided I wanted to try a smaller amount of photos, but make sure they were the highest quality of my photos which were cropped to an aspect ratio of 1:1 (to match the output of the SDXL model).

So I wrote a script to go through all my photos to get the top 100 highest quality images that were square:

```javascript
const fs = require('fs');
const { execSync } = require('child_process');

const directoryPath = './face';

fs.readdir(directoryPath, (err, files) => {
  if (err) {
    console.error('Error reading directory:', err);
    return;
  }

  const data = [];

  files.forEach((filename) => {
    const filePath = `${directoryPath}/${filename}`;

    try {
      const result = execSync(`identify -format "%wx%h\\n" "${filePath}"`, {
        encoding: 'utf-8',
        stdio: 'pipe'
      });

      const dim = result.trim().split('x');
      data.push({
        file: filename,
        width: Number(dim[0]),
        height: Number(dim[1])
      })
    } catch (error) {
      console.error(`Error running identify command for ${filename}:`, error.message);
    }
  });

  const images = data.filter((image) => image.width === image.height)
                     .filter((image) => image.width > 512)
                     .sort((imageA, imageB) => imageB.width - imageA.width)
                     .slice(0, 100)
                     .map((image) => image.file);
  images.forEach((imageFile) => execSync(`cp ./face/${imageFile} ./face-top100/${imageFile}`));
});
```

I also changed 2 other things during this attempt:

* Used an instance name of "jx265" instead of "James". The Stable Diffusion model already has a concept of what "James" might look like, and so by using a unique string, I can better identify myself when asking for output
* Used WD14 captioning instead of BLIP. There is lots of chat about which is better, I have no idea, but thought I would give it a go

Finally, I found a bunch of exported configs of people doing the similar type of thing as I was doing in Koya_ss, so I attempted importing some of those configs.

I ran into a bunch of issues on this attempt, mainly Out Of Memory errors. So on to the next attempt

## Attempt 5

Whilst looking around it was strange how much directly conflicting information there is around on how best to train these models. One opinion which came up was that you don't really need the regularization images. So I gave that a go. This time I didn't get OOM errors, but each epoch would take ~50 minutes.

## Attempt 6

I did everything the same as in Attempt 5, but I cut down the amount of photos of me down even further from 100 to 54 (not sure why I ended up on that number...). This time, each epoch was taking 27 minutes which was much more palatable.

Once the model has trained the first epoch I stopped the process and attempted to get some output using the prompt "Portrait headshot of jx265 man, realistic, full face, crisp, sharp photo <lora:jx265:1>". The output did look a lot closer to me than the output I was getting in Attempt 1, but there were no pictures there that would trick anyone that knows me into thinking it was an actual photo of me.

An interesting thing that I also found from this set of models was that Stable Diffusion would pretty much refuse to render anything other than a headshot of me. It would occasionally get my shoulders in if I asked for it, but it wouldn't put in the rest of my body. The reason for this, I figured, was because all the images it has been trained on were close-crops of my face. It actually didn't know what to render for the rest of my body and so refused to do so.

## Attempt 7

I switched over to using an RTX A5000 which seemed like a better fit for around the same price as the 4090. This time I ran the process with:

* WD14 captioning - making sure to prefix the tag list with `jx265, man,`
* No regularization images
* Only the 100 highest quality, square crop photos of me
* Maximum resolution of 512 x 512

Each epoch would take 90 minutes, which was again too long to run this for, so I cancelled the process.

## Attempt 8

After reading a bunch more online, I figured that I was attempting to throw too much data at the problem. Instead, what I needed was less images (maybe about 20 to 30), that were higher quality, 1024x1024 in size and not all close-crops on my face.

So I:

* Looked through all the images of me, sorted by largest filesize first
* Selected an image that had a non-occluded view of me
* Imported into GIMP
* Crop with fixed aspect ratio of 1:1
* Scaled the image to 1024x1024
* "Export As" into a new folder

Whilst cropping, I made sure to get some close-crops and some full body shots (as well as some in between) in order to show the full spectrum of what I looked like to the training process.

This time, each epoch would take 28 minutes, which was down to a reasonable level. I let the whole thing run for 4 hours and 40 minutes in order to get all 10 epochs.

And now I had it. These 10 models started to output pictures that looked very much like me indeed. Certainly some of the models were better than others, and occasionally it did weird things, but I could easily hand pick a few images from the set I created that looked no different from photos of me.

Furthermore, I could generate images that weren't just crops on my face.

## Attempt 9

There is a tab in the Automatic1111 user interface labelled "ADetailer". On my reading around online, people had mentioned it as a magic single button fix for getting more realistic pictures generated of faces. So naturally I enabled it generated some more images. And they were right, the outcome looked a better in small but significant ways.

## Attempt 10

I wanted to compare all of the models output using the same prompt and seed. Automatic1111 has a mechanism to do this. At the bottom of the Generate tab there is a "Script" tab. Opening that up you can add an "X/Y/Z Plot". For the X plot you need type "Prompt S/R". Within the prompt itself, add the lora reference to the end: "<lora:jx265:1>". Then in the Prompt S/R box, you need to put the same value again and then a comma separated list of all the other lora references: "<lora:jx265:1>, <lora:jx265-000001:1>, <lora:jx265-000002:1>, <lora:jx265-000003:1>, <lora:jx265-000004:1> <lora:jx265-000005:1>, <lora:jx265-000006:1>, <lora:jx265-000007:1>, <lora:jx265-000008:1> <lora:jx265-000009:1>".

This will generate an image that contains plots each of the models output alongside each other for easy comparison of the models.

## Attempt 11

Then on the tedious business of "prompt engineering" (NOTE: I do not consider any part of the prompt creation process as an "engineering" task). This involved a bit of looking around online for examples, and a bit of mashing all that together. Mostly it involved crossed fingers waiting for the result. Small iterations on the prompt did not result in small iterations of the output which is very frustrating. Anyway, here is a list of most of the prompts I attempted with varying success:

### Positive Prompt

```
- Photograph of James man, professional headshot, portrait <lora:James:1>
- Full face shot of James man with professional style like a corporate headshot <lora:James:1>
- Zoomed out Full face shot of James man with professional style like a corporate headshot <lora:James:1>
- Portrait headshot of jx265 man, realistic, full face, crisp, sharp photo <lora:jx265:1>
- jx265 man full body shot in a forest, photorealistic, sharp <lora:James:1>
- Portrait headshot of jx265 man, realistic, full face, crisp, sharp photo <lora:jx265:1>
- photo of jx265, <lora:jx265:1>, highlight hair, sitting outside restaurant, wearing dress, rim lighting, studio lighting, looking at the camera, dslr, ultra quality, sharp focus, tack sharp, dof, film grain, Fujifilm XT3, crystal clear, 8K UHD, highly detailed glossy eyes, high detailed skin, skin pores
- photo of jx265, man, highlight hair, office setting, rim lighting, studio lighting, looking at the camera, dslr, ultra quality, sharp focus, tack sharp, dof, film grain, Fujifilm XT3, crystal clear, 8K UHD, highly detailed glossy eyes, high detailed skin, skin pores, <lora:jx265-000001:1>
- photo of jx265, man, smiling, professional headshot, studio lighting, looking at the camera, ultra sharp quality, dof, out-of-focus background, crystal clear, highly detailed glossy eyes, high detailed skin, skin pores <lora:jx265:1>
- head shot of a jx265 man, white shirt, red tie, clean shaven, smiling, bright blue eyes <lora:jx265:1>
- portrait photo headshot of jx265 man, sharp focus, elegant, render, octane, detailed, award winning photography, masterpiece, rim lit, sharp focus, highly detailed, trending on artstation, nikon, kodak, 16:9, 50mm portrait photography, hard rim lighting photographybeta ar 2:3 beta upbeta upbeta <lora:jx265:1>
- (Realistic),masterpiece,best quality,cinematic lighting,natural shadow,highest detail,depth of field,insane details,intricate,aesthetic, photo of a jx265 man,full body,dynamic pose,BREAK Snow-capped mountains,alpine meadows,crystal-clear lakes,hiking trails,wildlife,pristine forests  <lora:jx265:1>
- Realistic photo, close-up: jx265 man smiling in black and white filter. Styled like Ansel Adams’ photography. <lora:jx265:1>
- 8k linkedin professional profile photo of jx265 in a suit with studio lighting, bokeh, corporate portrait headshot photograph best corporate photography photo winner, meticulous detail, hyperrealistic, centered uncropped symmetrical beautiful  <lora:jx265:1>
- portrait of (jx265 man) wearing a lawyer suit, bookshelf background, professional photo, white background, Amazing Details, Best Quality, 80mm Sigma f/1.4 or any ZEISS lens --tiled upscale <lora:jx265:1>
- portrait of (jx265 man) wearing a business suit, professional photo, white background, Amazing Details, Best Quality, Masterpiece, dramatic lighting highly detailed, analog photo, overglaze, 80mm Sigma f/1.4 or any ZEISS lens <lora:jx265:1>
- 8k linkedin professional profile photo of (((jx265 man))) with studio lighting, ((bokeh)), corporate portrait closeup headshot photograph best corporate photography photo winner, meticulous detail, hyperrealistic, centered uncropped symmetrical beautiful, solid blue background,  dramatic lighting highly detailed, 80mm Sigma f/1.4 or any ZEISS lens  <lora:jx265:1>
- photorealistic, visionary portrait of jx265 with weather-worn features, digitally enhanced, high contrast, chiaroscuro lighting technique, intimate, close-up, detailed, steady gaze, rendered in sepia tones, evoking rembrandt, timeless, expressive, highly detailed, sharp focus, high resolution <lora:jx265:1>
- photorealistic, visionary portrait of jx265, digitally enhanced, high contrast, chiaroscuro lighting technique, intimate, close-up, detailed, steady gaze, evoking rembrandt, timeless, expressive, highly detailed, sharp focus, high resolution <lora:jx265-000001:1>
- happy jx265, portrait photography, beautiful, morning sunlight, smooth light, shot on kodak portra 200, film grain, nostalgic mood <lora:jx265:1>
- jx265 photo portrait, film noir style, monochrome, high contrast, dramatic shadows, 1940s style, mysterious, cinematic <lora:jx265:1>
- jx265 in the cafe, comic, graphic illustration, comic art, graphic novel art, vibrant, highly detailed, colored, 2d minimalistic  <lora:jx265-000001:1>
```

### Negative Prompt

```
- ugly, duplicate, morbid, mutilated, out of frame, extra fingers, mutated hands, poorly drawn hands, poorly drawn face, mutation, deformed, ugly, blurry, bad anatomy, bad proportions, extra limbs, cloned face, out of frame, ugly, extra limbs, bad anatomy, gross proportions, malformed limbs, missing arms, missing legs, extra arms, extra legs, mutated hands, fused fingers, too many fingers, long neck, extra head, cloned head, extra body, cloned body, watermark. extra hands, clone hands, weird hand, weird finger, weird arm, (mutation:1.3), (deformed:1.3), (blurry), (bad anatomy:1.1), (bad proportions:1.2), out of frame, ugly, (long neck:1.2), (worst quality:1.4), (low quality:1.4), (monochrome:1.1), text, signature, watermark, bad anatomy, disfigured, jpeg artifacts, 3d max, grotesque, desaturated, blur, haze, polysyndactyly
- disfigured, ugly, bad, immature, cartoon, anime, 3d, painting, b&w
- old, wrinkles, mole, blemish,(oversmoothed, 3d render) scar, sad, severe, 2d, sketch, painting, digital art, drawing, disfigured, elongated body (deformed iris, deformed pupils, semi-realistic, cgi, sketch, cartoon, drawing, anime), text, cropped, out of frame, worst quality, low quality, jpeg artifacts, ugly, duplicate, morbid, mutilated, (extra fingers, mutated hands, poorly drawn hands, poorly drawn face), mutation, deformed, (blurry), dehydrated, bad anatomy, bad proportions, (extra limbs), cloned face, disfigured, gross proportions, (malformed limbs, missing arms, missing legs, extra arms, extra legs, fused fingers, too many fingers, NSFW), nude, underwear, muscular, elongated body, high contrast, airbrushed, blurry, disfigured, cartoon, blurry, dark lighting, low quality, low resolution, cropped, text, caption, signature, clay, kitsch, oversaturated
```

## Attempt 12

As I mentioned, I found the act of creating prompts really quite tedious. This is mostly because it wasn't really possible to tweak a prompt a small amount and expect small change in output. I might have been missing something in the Automatic1111 UI (because honestly it isn't the most intuitive interface ever), but that is the experience I had. So I figure, why not get an LLM to help generate prompts? I can give it the prompts I have listed above to seed the question, but then let the LLM churn out a whole bunch of varying prompts and then feed those into the SDXL model. I don't even really have to vet the output of the LLM because I only care about the output from SDXL. 

## What I missed

Didn't manually caption the training images
Lora strength <lora:jx265:0.8>
