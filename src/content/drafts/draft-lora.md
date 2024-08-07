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
+-----------------------------------------+----------+----------+-----------+-----------+
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

So in my next attempt, I tried to give the learning process all 1100 images. I quickly cancelled it after it showed that it would take 300 hours per epoch (which would cost more than $100 on runpod!). I clearly needed to alter my process a little bit and understand what was taking the time before I launched that my photos at it again.

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

I wanted to compare all of the models output using the same prompt and seed. Automatic1111 has a mechanism to do this. At the bottom of the Generate tab there is a "Script" tab. Opening that up you can add an "X/Y/Z Plot". For the X plot you need type "Prompt S/R". Within the prompt itself, add the lora reference to the end: "<lora:jx265:1>". Then in the Prompt S/R box, you need to put the same value again and then a comma separated list of all the other lora references: "<lora:jx265:1>, <lora:jx265-000001:1>, <lora:jx265-000002:1>, <lora:jx265-000003:1>, <lora:jx265-000004:1>, <lora:jx265-000005:1>, <lora:jx265-000006:1>, <lora:jx265-000007:1>, <lora:jx265-000008:1>, <lora:jx265-000009:1>".

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

So I asked ChatGPT-4o to "Create a positive and a negative prompt for Stable Diffusion that ask it to create a professional headshot style photo of a subject called jx265. Here are some positive prompts that have been used before: ... And here are some negative prompts used before: ..."

> **Positive Prompt:**
>
> LinkedIn professional headshot of (jx265 man), sharp focus, elegant, award-winning photography, natural background, masterpiece quality, rim lit, studio lighting, highly detailed, trending on artstation, Nikon, Kodak, 8K resolution, solid blue background, crisp, and clean, ultra-realistic, centered, looking directly at the camera <lora:jx265:1>
>
> **Negative Prompt:**
> 
> ugly, duplicate, morbid, mutilated, out of frame, extra fingers, mutated hands, poorly drawn hands, poorly drawn face, mutation, deformed, blurry, bad anatomy, bad proportions, extra limbs, cloned face, extra head, watermark, extra hands, weird hand, weird finger, weird arm, mutation:1.3, deformed:1.3, blurry, bad anatomy:1.1, bad proportions:1.2, long neck:1.2, worst quality:1.4, low quality:1.4, monochrome:1.1, text, signature, old, wrinkles, mole, blemish, disfigured, oversmoothed, 3d render, scar, sad, severe, 2d, sketch, painting, digital art, drawing, anime, cgi, dehydrated, elongated body, NSFW, nude, underwear, muscular, dark lighting, clay, kitsch, oversaturated

Pretty much just a re-mix of my input, which is fine. So I ask it to put a bit more effort into the prompts: "Can you create 10 more positive prompts with a large variation in the input words"

> 1. Business headshot of jx265, indoor setting, formal attire, sophisticated, professional lighting, clear background, DSLR quality, highly detailed, elegant composition, neutral color tones <lora:jx265:1>
> 2. Portrait of jx265 man in a corporate office, wearing glasses, natural light, professional style, ultra-sharp focus, shallow depth of field, modern background, realistic textures, high-resolution, pristine <lora:jx265:1>
> 3. High-definition profile photo of jx265, clean-shaven, business suit, confident expression, well-lit, polished look, magazine-quality, studio backdrop, finely detailed, vibrant colors <lora:jx265:1>
> 4. Elegant headshot of jx265 man, artistic lighting, bokeh effect, well-balanced composition, sharp details, realistic, high dynamic range, professional attire, medium shot, warm tones <lora:jx265:1>
> 5. LinkedIn profile picture of jx265, smart casual, smiling, outdoor background, natural light, sharp focus, high-quality, vibrant setting, contemporary style, impeccable details <lora:jx265:1>
> 6. 8K portrait photo of jx265 man, in a modern office, serious expression, crisp and clear, soft lighting, realistic skin texture, professional appearance, full-frame, vibrant resolution <lora:jx265:1>
> 7. Studio headshot of jx265, classic portrait style, minimalistic background, high detail, expert lighting, professional grade, natural expression, modern look, razor-sharp focus, color accuracy l<lora:jx265:1>
> 8. Close-up headshot of jx265, casual wear, relaxed look, interior setting, natural shadows, realistic details, ultra-high-resolution, artistic composition, engaging gaze, vivid clarity <lora:jx265:1>
> 9. Professional photo of jx265, formal outfit, confident stance, corporate background, softbox lighting, hyper-realistic quality, crystal clear details, natural posture, visually striking <lora:jx265:1>
> 10. Highly detailed portrait of jx265 man, business environment, sharp focus, elegant lighting, photorealistic quality, natural colors, crisp image, dynamic composition, serene expression <lora:jx265:1>

All of which are worth trying out in SDXL. I then wanted it to create some more prompts which were not about profession headshots: "And now remove the idea of it being professional, headshot or business-like. Create 10 prompts that will create striking, realistic photos that resemble jx265. Make sure to add more words and detail to each prompt"

> 1. Photorealistic image of jx265 sitting in a cozy corner of a vintage cafe, autumn afternoon, natural light streaming in through large windows, candid moment captured while sipping a steaming cup of coffee, highly detailed textures on wooden table and chair, vibrant colors of decor and foliage, warm ambiance, soft shadows, intricate details in clothing, relaxed and introspective expression <lora:jx265:1>
> 2. jx265 in a lush, blooming garden, surrounded by a myriad of colorful flowers, golden hour lighting creating a warm, enchanting glow, wearing casual and comfortable clothing, sitting on a rustic bench, soft focus on the background, realistic textures of plants and flowers, serene and contemplative expression, rich and vibrant color palette, ultra-high-resolution, capturing the tranquility and beauty of nature <lora:jx265:1>
> 3. Portrait of jx265 during a rainy day, standing under a classic black umbrella, wet city street background with reflections on the pavement, realistic raindrops and puddles, moody and atmospheric lighting, sharp details on face and clothing, highly realistic water textures, reflective surfaces of buildings and cars, capturing the essence of a rainy urban scene, introspective and thoughtful expression <lora:jx265:1>
> 4. Close-up of jx265 at a serene beach, during sunset, wind gently blowing through hair, relaxed and happy expression, golden sunlight casting a warm glow, waves and sand in the background, photorealistic textures of the beach environment, detailed and natural looking hair, realistic skin tones, sense of peace and contentment, vibrant and rich colors, high-resolution image capturing the beauty of the moment <lora:jx265:1>
> 5. jx265 dancing energetically at a colorful festival, lively and bustling background filled with festival-goers, joy and motion beautifully captured, vibrant atmosphere with bright lights and decorations, crisp details on clothing and face, motion blur adding a sense of movement, festival lights illuminating the scene, photorealistic quality, high energy and excitement, detailed patterns and textures, wide smile and expressive eyes <lora:jx265:1>
> 6. Intimate portrait of jx265 reading a book by a crackling fireplace, warm and cozy lighting casting a gentle glow, detailed textures on the book cover and pages, calm and focused expression, realistic fire glow reflecting on face and surroundings, high-resolution image capturing every detail from the crackling embers to the soft fabric of a nearby blanket, serene and peaceful mood, soft shadows and rich warm tones, bookshelf in the background <lora:jx265:1>
> 7. Photorealistic image of jx265 hiking in the breathtaking mountains, panoramic and stunning landscape with towering peaks, rugged and practical hiking attire, natural lighting showcasing the beauty of nature, sharp focus on jx265 with detailed textures on clothing and gear, expansive scenery in the background, immersive depth and sense of adventure, vivid and rich colors, capturing the essence of exploration and connection with nature, serene and determined expression <lora:jx265:1>
> 8. jx265 playing an acoustic guitar in a sun-dappled park, sunlight filtering through the leaves of tall trees, realistic and intricate wood textures on the guitar, relaxed posture and engaging smile, high-detail in clothing and facial features, lifelike and vibrant park background with people walking and greenery, photorealistic quality, capturing a moment of musical expression and joy, vibrant and rich colors, sense of peace and connection with nature <lora:jx265:1>
> 9. Striking photorealistic image of jx265 exploring a bustling and vibrant marketplace, dynamic background filled with colorful stalls and diverse crowd, sharp focus on jx265 with detailed textures on clothing and skin, candid moment captured while admiring a beautifully crafted item, lively atmosphere with rich and varied colors, realistic lighting and shadows, depiction of cultural richness and human interaction, ultra-realistic quality, sense of discovery and curiosity, detailed and expressive facial features <lora:jx265:1>
> 10. jx265 enjoying an outdoor concert during a warm summer evening, dramatic stage lighting creating an energetic and vibrant atmosphere, vivid colors highlighting the excitement of the event, animated and expressive facial features, photorealistic quality, detailed crowd in the background, immersive feel with realistic textures on clothing and surroundings, capturing the thrill of live music, joyous and energetic expression, soft shadows and well-defined lighting adding depth <lora:jx265:1>

Finally, I wanted ChatGPT to give me some more general advice on how to create an image with SDXL that looked like me: "How can I craft a prompt for sdxl model such that it will most resemble the LORA named jx265?"

> To craft a prompt for the SDXL model that will most closely resemble the LORA named jx265, you should consider incorporating detailed descriptors and context. This includes physical features, environmental settings, emotions, actions, and any specific attributes that the LORA captures well.
> Here’s a detailed breakdown:
>
> 1. Subject Details: Include general features about jx265 like gender, age, hair color, skin tone, attire, etc.
> 2. Setting and Environment: Describe the surroundings to add context and richness.
> 3. Lighting and Mood: Specify the type of lighting and the overall mood you want to capture in the image.
> 4. Focus and Detail: Mention camera settings or descriptors that highlight the level of detail and focus you require.
> 5. Emotional Tone or Action: Provide insights into the subject’s emotion or action, which lends personality and dynamism to the image.
> 6. LORA Specificity: Reference the LORA (jx265) explicitly to ensure the model you are using is aligned with the characteristics captured by the LORA.
>
> Here is a crafted prompt that encapsulates these elements:
>
> **Example Prompt:**
>
> Photorealistic portrait of jx265, a young man in his late 20s, with short dark hair, fair skin, and wearing a casual button-up shirt. The scene is set in a lush garden during golden hour, with sunlight casting a warm, soft glow. The background is slightly out of focus, creating a gentle bokeh effect with vibrant floral tones. The man is sitting on a rustic wooden bench, reading a book with a relaxed and contented expression. Detailed textures of the garden environment and his clothing are visible, with crisp, clear focus on his facial features. The LORA named jx265 should be distinctly referenced, ensuring high detail and likeness, capturing natural shadows and realistic skin tones. Ultra-high-resolution image with high dynamic range, capturing the serene and tranquil mood flawlessly. <lora:jx265:1>
>
> **Breakdown:**
>
> * Subject Details: “a young man in his late 20s, with short dark hair, fair skin, and wearing a casual button-up shirt.”
> * Setting and Environment: “The scene is set in a lush garden during golden hour.”
> * Lighting and Mood: “sunlight casting a warm, soft glow.”
> * Focus and Detail: “crisp, clear focus on his facial features,” “high detail and likeness.”
> * Emotional Tone or Action: “sitting on a rustic wooden bench, reading a book with a relaxed and contented expression.”
> * LORA Specificity: “lora:jx265:1”
>
> **Adaptable Template:**
>
> You can also use this template to create different prompts:
>
> Photorealistic portrait of jx265, [subject description: age, hair color, skin tone, attire]. The scene is set in [environment: describe setting and time of day], with [lighting: type of lighting and effects]. The background features [background detail: describe background]. The subject is [action/emotion: what the subject is doing and their expression]. Detailed textures of [specific visual elements] are visible, with [camera settings: focus, resolution, dynamic range]. The likeness of the LORA named jx265 should be distinctly referenced, ensuring high detail, capturing [specific features: natural shadows, realistic skin tones]. [Extra descriptors: any additional details]. <lora:jx265:1>
>
> This approach helps ensure that the SDXL model captures the distinctive characteristics represented by the LORA named jx265, resulting in a highly similar resemblance.





"Create a positive prompt for Stable Diffusion that asks it to create a happy photo of a subject called jx265. The prompt must be written in a way that will create an image that resembles jx265 as much as possible. It must also output a very photographic image"
> Create a vibrant, high-resolution photograph of a person named jx265. jx265 should be depicted smiling warmly, with a natural and joyful expression. Ensure the lighting is soft and flattering, bringing out the contours of their face in a realistic manner. The background should be slightly blurred to emphasize the subject, resembling a professional portrait photography style. Pay close attention to details such as skin texture, hair, and eye sparkle to achieve a lifelike result. Include elements that suggest a warm, sunny day with natural surroundings, enhancing the overall positivity and happiness conveyed by the image.

> "Create a high-resolution photograph of jx265, a person with light brown skin, curly black hair, and bright green eyes. They should be seated in a relaxed pose, smiling warmly with a slight head tilt. The lighting should be natural and diffused, casting gentle shadows to create depth. The background should feature a slightly blurred park scene with sunlight filtering through trees, enhancing the focus on jx265. They are wearing a light blue shirt with a subtle pattern and simple stud earrings. Pay close attention to the fine details like skin texture, hair strands, and eye reflections to ensure a lifelike appearance."

"Can you create 20 more example prompts of the same nature, but make sure to a lot of variation between the different prompts. Perhaps use different art styles or ask for different settings making sure to generate high quality, photogenic and realistic output"

> 1. Vintage Style Portrait: “Create a high-resolution vintage-style photograph of jx265. Jx265 should be dressed in classic 1950s attire, such as a pin-up dress or neat suit, smiling joyfully. Utilize sepia tones, subtle film grain, and slightly softened edges. The setting should resemble an old-timey studio with vintage props like a rotary phone and floral wallpaper.”
> 2. Urban Street Photography: “Generate a modern, high-resolution photograph of jx265 standing on a bustling city street at dusk. Jx265 should be smiling brightly, with the golden light from streetlights and headlights casting a warm glow on their face. Capture the cityscape with blurred motion of pedestrians and vehicles in the background.”
> 3. Black and White Photography: “Produce a classic black and white photograph of jx265 with a happy expression, standing against an urban backdrop. Emphasize strong contrasts and deep shadows to highlight jx265’s facial features, with detailed textures on clothing and a finely structured urban environment for added realism.”
> 4. Beach Sunset Scene: “Create a high-resolution photograph of jx265 on a sandy beach at sunset, dressed in casual summer attire. Jx265 should be smiling warmly, with the sun setting behind them casting a golden glow and slight lens flare. Waves gently lap at the shore in the background, with footprints in the sand adding detail.”
> 5. Natural Forest Setting: “Generate a high-resolution photograph of jx265 standing in a lush, green forest, wearing outdoor gear. Jx265 is smiling and bathed in natural sunlight filtering through the canopy, casting dappled light and shadows. Forest elements like ferns, fallen leaves, and tree bark should be clearly detailed.”
> 6. Art Deco Style: “Produce an art deco-inspired high-resolution photograph of jx265, with geometric shapes and elegant lines incorporated into the background and outfit. Jx265, smiling, dressed in a sleek, 1920s-inspired outfit with gold and black details. Use luxurious, clean lighting to create an upscale, glamorous setting.”
> 7. Rainy Day Portrait: “Create a high-resolution photograph of jx265 on a rainy day, standing under a colorful umbrella and smiling joyfully. Details should include raindrops on the umbrella, reflections in puddles, and a brightly lit, wet urban environment. The sky should be overcast with gentle raindrops visible in the air.”
> 8. Cinematic Still: “Generate a high-resolution cinematic still of jx265, with dramatic, natural lighting and a shallow depth of field. Jx265 should be smiling while interacting with a recognizable urban setting, with a slightly blurred background emphasizing bokeh effects from city lights and street elements.”
> 9. Sports Theme: “Produce a high-resolution photograph of jx265 on a sports field, smiling confidently in athletic wear suited for the specific sport (such as soccer or basketball gear). Capture dynamic movement in the background with teammates or equipment, and strong, natural lighting highlighting their athleticism.”
> 10. Outdoor Picnic: “Create a high-resolution photograph of jx265 at a beautifully arranged outdoor picnic, surrounded by friends and family. Jx265 is smiling happily with a feast laid out on a blanket, vibrant fruits, and checkered cloth. Natural sunlight, with a clear sky and distant trees, adds a summery ambiance.”
> 11. Winter Wonderland: “Generate a high-resolution photograph of jx265 in a snowy landscape, wearing a cozy winter coat, scarf, and gloves. Jx265 should be smiling joyfully with softly falling snowflakes visible. Background details include pine trees dusted with snow, sparkling icicles, and a serene, overcast sky.”
> 12. Retro Polaroid Look: “Produce a high-resolution photograph of jx265 with a retro Polaroid style, smiling widely. Include a classic white Polaroid border and slightly faded colors. The setting should incorporate a whimsical, nostalgic background, such as a carnival or beach scene, with a slight vignette effect.”
> 13. Travel Adventure: “Create a high-resolution photograph of jx265 at a famous landmark such as the Eiffel Tower or the Great Wall of China, smiling excitedly. Ensure clear details of the landmark in the background, with Jx265 engaged in a candid, travel-related activity, such as taking photos or enjoying local cuisine.”
> 14. Cafe Vibes: “Generate a high-resolution photograph of jx265 in a quaint, cozy cafe, smiling pleasantly with a steaming cup of coffee in hand. The cafe environment should be warmly lit, with detailed elements like rustic wooden tables, latte art, and aromatic pastries in the background.”
> 15. Glamour Shot: “Produce a high-resolution glamour photograph of jx265, dressed elegantly in evening wear, such as a chic gown or tailored suit. Jx265 should be smiling confidently, with dramatic studio lighting creating refined highlights and shadows. The background should be a rich, deep color with subtle patterns.”
> 16. Underwater Fun: “Create a high-resolution photograph of jx265 swimming underwater in a crystal-clear pool, smiling and surrounded by bubbles. Use clear, bright lighting to capture the underwater environment, with ripples and sunlight creating shimmering patterns on their face and the pool floor.”
> 17. Autumn Leaves: “Generate a high-resolution photograph of jx265 in a park during autumn, dressed in warm, casual clothing. Jx265 is smiling while surrounded by vibrant fall leaves in shades of red, orange, and yellow. Include warm sunlight, casting long shadows and a crisp, clear day.”
> 18. Festival Scene: “Produce a high-resolution photograph of jx265 enjoying a music festival, with a big joyful smile. Capture the vibrancy of the festival with colorful stage lights, banners, and an excited crowd. Ensure environmental details like festival-goers, stage equipment, and clear sky contribute to the atmosphere.”
> 19. Sketch Style: “Create a high-resolution photograph of jx265 in a hand-drawn sketch style, smiling happily. Use subtle pencil shading and lines to give the appearance of a high-quality sketch while maintaining realistic facial features and background elements like a lively cafe scene or tranquil park setting.”
> 20. Portrait with Pet: “Generate a high-resolution photograph of jx265 holding a pet, such as a dog or cat, both smiling happily. Jx265 should be in a comfortable, cozy setting like a home living room with detailed elements such as a plush sofa, warm lighting, and personal decorations in the background.”

## Conclusion

I would love to add outcome images for each of the attempts above, but now that I know how easy the process is to generate a model based off of someone's face (and how few training images it needs), I will not be doing that.

The key things that I found out whilst training a LoRA are:

* You only need around 20 images
    * They need to be different crops of the person (face, shoulder-length, full body)
    * They need to be square (1024x1024) images to match the SDXL model output
* Regularization images are not necessary
* The instance prompt needs to be a unique string (jx265)
* Use WD14 Captioning

And when generating an output image

* Use ADetailer for a more realistic looking face
* Find examples of negative prompts online (or use the ones in this post)
* Use the X/Y/Z plotter to try the same prompt and seed with the various epochs of the model
* Use ChatGPT to help with prompt creation because it is a tedious business


## Issues

The model had various recurring issues when attempting to generate images:

**Feet/Legs**


**Hands**


**Mouth/Teeth**


**Art Style**


**Gender**


**Other**


- LinkedIn professional headshot of (jx265 man), sharp focus, elegant, award-winning photography, natural background, masterpiece quality, rim lit, studio lighting, highly detailed, trending on artstation, Nikon, Kodak, 8K resolution, solid blue background, crisp, and clean, ultra-realistic, centered, looking directly at the camera <lora:jx265:1>
    - 00002-1142774022.png
- Business headshot of jx265, indoor setting, formal attire, sophisticated, professional lighting, clear background, DSLR quality, highly detailed, elegant composition, neutral color tones <lora:jx265:1>
    - 00003-566578047.png
- Portrait of jx265 man in a corporate office, wearing glasses, natural light, professional style, ultra-sharp focus, shallow depth of field, modern background, realistic textures, high-resolution, pristine <lora:jx265:1>
    - 00004-65682440.png
- High-definition profile photo of jx265, clean-shaven, business suit, confident expression, well-lit, polished look, magazine-quality, studio backdrop, finely detailed, vibrant colors <lora:jx265:1>
    - 00005-2037759503.png
- Elegant headshot of jx265 man, artistic lighting, bokeh effect, well-balanced composition, sharp details, realistic, high dynamic range, professional attire, medium shot, warm tones <lora:jx265:1>
    - 00006-1106930983.png
- LinkedIn profile picture of jx265, smart casual, smiling, outdoor background, natural light, sharp focus, high-quality, vibrant setting, contemporary style, impeccable details <lora:jx265:1>
    - 00007-1742693269.png
- 8K portrait photo of jx265 man, in a modern office, serious expression, crisp and clear, soft lighting, realistic skin texture, professional appearance, full-frame, vibrant resolution <lora:jx265:1>
    - 00008-2637462755.png
- Studio headshot of jx265, classic portrait style, minimalistic background, high detail, expert lighting, professional grade, natural expression, modern look, razor-sharp focus, color accuracy l<lora:jx265:1>
    - 00009-30945775.png
- Close-up headshot of jx265, casual wear, relaxed look, interior setting, natural shadows, realistic details, ultra-high-resolution, artistic composition, engaging gaze, vivid clarity <lora:jx265:1>
    - 00010-2277354615.png
- Professional photo of jx265, formal outfit, confident stance, corporate background, softbox lighting, hyper-realistic quality, crystal clear details, natural posture, visually striking <lora:jx265:1>
    - 00011-3147170040.png
- Highly detailed portrait of jx265 man, business environment, sharp focus, elegant lighting, photorealistic quality, natural colors, crisp image, dynamic composition, serene expression <lora:jx265:1>
    - 00012-3911615540.png
- Photorealistic image of jx265 sitting in a cozy corner of a vintage cafe, autumn afternoon, natural light streaming in through large windows, candid moment captured while sipping a steaming cup of coffee, highly detailed textures on wooden table and chair, vibrant colors of decor and foliage, warm ambiance, soft shadows, intricate details in clothing, relaxed and introspective expression <lora:jx265:1>
    - 00013-4022569439.png
- jx265 in a lush, blooming garden, surrounded by a myriad of colorful flowers, golden hour lighting creating a warm, enchanting glow, wearing casual and comfortable clothing, sitting on a rustic bench, soft focus on the background, realistic textures of plants and flowers, serene and contemplative expression, rich and vibrant color palette, ultra-high-resolution, capturing the tranquility and beauty of nature <lora:jx265:1>
    - 00014-3327410621.png
- Portrait of jx265 during a rainy day, standing under a classic black umbrella, wet city street background with reflections on the pavement, realistic raindrops and puddles, moody and atmospheric lighting, sharp details on face and clothing, highly realistic water textures, reflective surfaces of buildings and cars, capturing the essence of a rainy urban scene, introspective and thoughtful expression <lora:jx265:1>
    - 00015-4057013405.png
- Close-up of jx265 at a serene beach, during sunset, wind gently blowing through hair, relaxed and happy expression, golden sunlight casting a warm glow, waves and sand in the background, photorealistic textures of the beach environment, detailed and natural looking hair, realistic skin tones, sense of peace and contentment, vibrant and rich colors, high-resolution image capturing the beauty of the moment <lora:jx265:1>
    - 00016-3649981882.png
- jx265 dancing energetically at a colorful festival, lively and bustling background filled with festival-goers, joy and motion beautifully captured, vibrant atmosphere with bright lights and decorations, crisp details on clothing and face, motion blur adding a sense of movement, festival lights illuminating the scene, photorealistic quality, high energy and excitement, detailed patterns and textures, wide smile and expressive eyes <lora:jx265:1>
    - NOPE, all female
- Intimate portrait of jx265 reading a book by a crackling fireplace, warm and cozy lighting casting a gentle glow, detailed textures on the book cover and pages, calm and focused expression, realistic fire glow reflecting on face and surroundings, high-resolution image capturing every detail from the crackling embers to the soft fabric of a nearby blanket, serene and peaceful mood, soft shadows and rich warm tones, bookshelf in the background <lora:jx265:1>
    - 00017-1257799735.png
- Photorealistic image of jx265 hiking in the breathtaking mountains, panoramic and stunning landscape with towering peaks, rugged and practical hiking attire, natural lighting showcasing the beauty of nature, sharp focus on jx265 with detailed textures on clothing and gear, expansive scenery in the background, immersive depth and sense of adventure, vivid and rich colors, capturing the essence of exploration and connection with nature, serene and determined expression <lora:jx265:1>
    - 00018-1684991931.png
- jx265 playing an acoustic guitar in a sun-dappled park, sunlight filtering through the leaves of tall trees, realistic and intricate wood textures on the guitar, relaxed posture and engaging smile, high-detail in clothing and facial features, lifelike and vibrant park background with people walking and greenery, photorealistic quality, capturing a moment of musical expression and joy, vibrant and rich colors, sense of peace and connection with nature <lora:jx265:1>
    - 00019-109377204.png
- Striking photorealistic image of jx265 exploring a bustling and vibrant marketplace, dynamic background filled with colorful stalls and diverse crowd, sharp focus on jx265 with detailed textures on clothing and skin, candid moment captured while admiring a beautifully crafted item, lively atmosphere with rich and varied colors, realistic lighting and shadows, depiction of cultural richness and human interaction, ultra-realistic quality, sense of discovery and curiosity, detailed and expressive facial features <lora:jx265:1>
    - 00020-1215529880.png
- jx265 enjoying an outdoor concert during a warm summer evening, dramatic stage lighting creating an energetic and vibrant atmosphere, vivid colors highlighting the excitement of the event, animated and expressive facial features, photorealistic quality, detailed crowd in the background, immersive feel with realistic textures on clothing and surroundings, capturing the thrill of live music, joyous and energetic expression, soft shadows and well-defined lighting adding depth <lora:jx265:1>
    - 00021-2207187284.png
- Photorealistic portrait of jx265, a young man in his late 20s, with short dark hair, fair skin, and wearing a casual button-up shirt. The scene is set in a lush garden during golden hour, with sunlight casting a warm, soft glow. The background is slightly out of focus, creating a gentle bokeh effect with vibrant floral tones. The man is sitting on a rustic wooden bench, reading a book with a relaxed and contented expression. Detailed textures of the garden environment and his clothing are visible, with crisp, clear focus on his facial features. The LORA named jx265 should be distinctly referenced, ensuring high detail and likeness, capturing natural shadows and realistic skin tones. Ultra-high-resolution image with high dynamic range, capturing the serene and tranquil mood flawlessly. <lora:jx265:1>
    - 00022-2836402723.png
- Create a vibrant, high-resolution photograph of a person named jx265. jx265 should be depicted smiling warmly, with a natural and joyful expression. Ensure the lighting is soft and flattering, bringing out the contours of their face in a realistic manner. The background should be slightly blurred to emphasize the subject, resembling a professional portrait photography style. Pay close attention to details such as skin texture, hair, and eye sparkle to achieve a lifelike result. Include elements that suggest a warm, sunny day with natural surroundings, enhancing the overall positivity and happiness conveyed by the image. <lora:jx265:1>
    - 00023-3381869203
- Create a high-resolution photograph of jx265, a person with light brown skin, curly black hair, and bright green eyes. They should be seated in a relaxed pose, smiling warmly with a slight head tilt. The lighting should be natural and diffused, casting gentle shadows to create depth. The background should feature a slightly blurred park scene with sunlight filtering through trees, enhancing the focus on jx265. They are wearing a light blue shirt with a subtle pattern and simple stud earrings. Pay close attention to the fine details like skin texture, hair strands, and eye reflections to ensure a lifelike appearance. <lora:jx265:1>
    - 00024-706928576
- Create a high-resolution vintage-style photograph of jx265. Jx265 should be dressed in classic 1950s attire, such or neat suit, smiling joyfully. Utilize sepia tones, subtle film grain, and slightly softened edges. The setting should resemble an old-timey studio with vintage props like a rotary phone and floral wallpaper. <lora:jx265:1>
    - 00025-2640895880
- Generate a modern, high-resolution photograph of jx265 standing on a bustling city street at dusk. Jx265 should be smiling brightly, with the golden light from streetlights and headlights casting a warm glow on their face. Capture the cityscape with blurred motion of pedestrians and vehicles in the background. <lora:jx265:1>
    - 00026-639930909
- Produce a classic black and white photograph of jx265 with a happy expression, standing against an urban backdrop. Emphasize strong contrasts and deep shadows to highlight jx265’s facial features, with detailed textures on clothing and a finely structured urban environment for added realism. <lora:jx265:1>
    - 00027-3083744684
- Create a high-resolution photograph of jx265 on a sandy beach at sunset, dressed in casual summer attire. Jx265 should be smiling warmly, with the sun setting behind them casting a golden glow and slight lens flare. Waves gently lap at the shore in the background, with footprints in the sand adding detail. <lora:jx265:1>
    - 00028-2063670553
- Generate a high-resolution photograph of jx265 standing in a lush, green forest, wearing outdoor gear. Jx265 is smiling and bathed in natural sunlight filtering through the canopy, casting dappled light and shadows. Forest elements like ferns, fallen leaves, and tree bark should be clearly detailed. <lora:jx265:1>
    - 00029-198308439
- Produce an art deco-inspired high-resolution photograph of jx265, with geometric shapes and elegant lines incorporated into the background and outfit. Jx265, smiling, dressed in a sleek, 1920s-inspired outfit with gold and black details. Use luxurious, clean lighting to create an upscale, glamorous setting. <lora:jx265:1>
    - 00030-4146729375
- Create a high-resolution photograph of jx265 on a rainy day, standing under a colorful umbrella and smiling joyfully. Details should include raindrops on the umbrella, reflections in puddles, and a brightly lit, wet urban environment. The sky should be overcast with gentle raindrops visible in the air. <lora:jx265:1>
    - 00031-3925698473
- Generate a high-resolution cinematic still of jx265, with dramatic, natural lighting and a shallow depth of field. Jx265 should be smiling while interacting with a recognizable urban setting, with a slightly blurred background emphasizing bokeh effects from city lights and street elements. <lora:jx265:1>
    - 00032-2485099629
- Produce a high-resolution photograph of jx265 on a sports field, smiling confidently in athletic wear suited for the specific sport (such as soccer or basketball gear). Capture dynamic movement in the background with teammates or equipment, and strong, natural lighting highlighting their athleticism. <lora:jx265:1>
    - 00033-480587006
- Create a high-resolution photograph of jx265 at a beautifully arranged outdoor picnic, surrounded by friends and family. Jx265 is smiling happily with a feast laid out on a blanket, vibrant fruits, and checkered cloth. Natural sunlight, with a clear sky and distant trees, adds a summery ambiance. <lora:jx265:1>
    - 00034-1118151046
- Generate a high-resolution photograph of jx265 in a snowy landscape, wearing a cozy winter coat, scarf, and gloves. Jx265 should be smiling joyfully with softly falling snowflakes visible. Background details include pine trees dusted with snow, sparkling icicles, and a serene, overcast sky. <lora:jx265:1>
    - 00035-1537139638
- Produce a high-resolution photograph of jx265 with a retro Polaroid style, smiling widely. Include a classic white Polaroid border and slightly faded colors. The setting should incorporate a whimsical, nostalgic background, such as a carnival or beach scene, with a slight vignette effect. <lora:jx265:1>
    - 00036-3923708682
- Create a high-resolution photograph of jx265 at a famous landmark such as the Eiffel Tower or the Great Wall of China, smiling excitedly. Ensure clear details of the landmark in the background, with Jx265 engaged in a candid, travel-related activity, such as taking photos or enjoying local cuisine. <lora:jx265:1>
    - 00037-3885217923
- Generate a high-resolution photograph of jx265 in a quaint, cozy cafe, smiling pleasantly with a steaming cup of coffee in hand. The cafe environment should be warmly lit, with detailed elements like rustic wooden tables, latte art, and aromatic pastries in the background. <lora:jx265:1>
    - Just images of coffee shops
- Produce a high-resolution glamour photograph of jx265, dressed elegantly in evening wear, such as a chic gown or tailored suit. Jx265 should be smiling confidently, with dramatic studio lighting creating refined highlights and shadows. The background should be a rich, deep color with subtle patterns. <lora:jx265:1>
    - 00038-1314761103
- Create a high-resolution photograph of jx265 swimming underwater in a crystal-clear pool, smiling and surrounded by bubbles. Use clear, bright lighting to capture the underwater environment, with ripples and sunlight creating shimmering patterns on their face and the pool floor. <lora:jx265:1>
    - All females
- Generate a high-resolution photograph of jx265 in a park during autumn, dressed in warm, casual clothing. Jx265 is smiling while surrounded by vibrant fall leaves in shades of red, orange, and yellow. Include warm sunlight, casting long shadows and a crisp, clear day. <lora:jx265:1>
    - 00039-2811510760
- Produce a high-resolution photograph of jx265 enjoying a music festival, with a big joyful smile. Capture the vibrancy of the festival with colorful stage lights, banners, and an excited crowd. Ensure environmental details like festival-goers, stage equipment, and clear sky contribute to the atmosphere. <lora:jx265:1>
    - 00040-2045349419
- Create a high-resolution photograph of jx265 in a hand-drawn sketch style, smiling happily. Use subtle pencil shading and lines to give the appearance of a high-quality sketch while maintaining realistic facial features and background elements like a lively cafe scene or tranquil park setting. <lora:jx265:1>
    - 00041-1493791435
- Generate a high-resolution photograph of jx265 holding a pet, such as a dog or cat, both smiling happily. Jx265 should be in a comfortable, cozy setting like a home living room with detailed elements such as a plush sofa, warm lighting, and personal decorations in the background. <lora:jx265:1>
    - 00042-666032749

417 separate images

594 images for all generated since the start