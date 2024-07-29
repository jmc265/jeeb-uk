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

- https://aituts.com/sdxl-lora/
- https://rentry.org/59xed3#number-of-steps
- https://medium.com/@yushantripleseven/dreambooth-sdxl-using-kohya-ss-on-vast-ai-10e1bfa26eed

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

## Attempt 5

jx265 model name

## Attempt 6

WD14 captioning

