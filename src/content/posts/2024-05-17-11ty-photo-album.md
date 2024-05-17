---
title:  "Creating a photo album using 11ty"
permalink: 11ty-photo-album/
layout: post
tags:
  - 11ty
  - eleventy
  - photography
  - gallery
  - javascript
  - html
  - nunjucks
---

This blog is created using the wonderful static site generator [11ty](https://www.11ty.dev/). I wanted to add a [single page](https://jeeb.uk/photos) which would show a gallery of all the photos posted in all of the posts on the site.

---

The below few snippets show how I managed to accomplish that with a few lines of Javascript.

Firstly, we need to add a custom collection which would list every post that has the tag "photography":

```javascript
eleventyConfig.addCollection("gallery", (collection) => {
        return collection
            .getFilteredByTag("photography")
            .sort((p1, p2) => p1.date - p2.date);
    });
```

Then, on `photos.njk` we will iterate over the collection and using a custom filter (shown underneath), we will output each individual image:

```html
<div>
    {% for post in collections.gallery | reverse %}
        {% for image in post.content | markdownToImagesOnly %}
            {{ image | safe }}
        {% endfor %}
    {% endfor %}
</div>
```

And finally, the actual meat of the solution which is a custom filter that renders the Markdown to HTML and then extracts all the `<img>` tags:

```javascript
    eleventyConfig.addFilter("markdownToImagesOnly", str => {
        const markdownLibrary = markdownIt({html: true});
        const inline = markdownLibrary.renderInline(str).replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
        return inline.match(/<img\s+[^>]*?>/g);
    });
```

And with that, the solution is complete. You can see the results on [jeeb.uk/photos](https://jeeb.uk/photos).
