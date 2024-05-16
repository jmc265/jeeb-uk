---
title:  "LoRA" 
permalink: lora/
layout: post
draft: true 
tags:
  - programming
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
