const { DateTime } = require("luxon");
const fs = require("fs");
const pluginRss = require("@11ty/eleventy-plugin-rss");
const pluginSyntaxHighlight = require("@11ty/eleventy-plugin-syntaxhighlight");
const embedYouTube = require("eleventy-plugin-youtube-embed");
const markdownIt = require("markdown-it");
const slugify = require("./src/eleventy/slugify");
const Image = require('@11ty/eleventy-img');
const { eleventyImageTransformPlugin } = require("@11ty/eleventy-img");
const { parseHTML } = require('linkedom')

module.exports = function (eleventyConfig) {
    eleventyConfig.setUseGitIgnore(false);
    eleventyConfig.addPassthroughCopy({
        "src/_includes/img": "assets/img",
        "src/_includes/css": "assets/css",
        "src/_includes/js": "assets/js",
        "src/_includes/favicon": "/"
    });

    // Add plugins
    eleventyConfig.addPlugin(pluginRss);
    eleventyConfig.addPlugin(pluginSyntaxHighlight, {
        templateFormats: ["*"],
        preAttributes: {
            tabindex: 0
        },
        codeAttributes: {},
    });
    eleventyConfig.addPlugin(embedYouTube, {
        lite: true
    });

    eleventyConfig.addPlugin(eleventyImageTransformPlugin, {
		extensions: "html",
		formats: ["avif", "jpeg"],
		widths: [350, 700, 1400, "auto"],
		defaultAttributes: {
			loading: "lazy",
			decoding: "async",
            sizes: "(max-width: 400px) 350px, (max-width: 600px) 550px, 700px",
		},
        filenameFormat: function (id, src, width, format, options) {
            return `${src}-${width}.${format}`;
        }
	});

    eleventyConfig.addLayoutAlias("post", "layouts/post.njk");
    eleventyConfig.addLayoutAlias("gallery", "layouts/gallery.njk");

    eleventyConfig.addFilter("limit", (arr, limit) => arr.slice(0, limit));

    // https://html.spec.whatwg.org/multipage/common-microsyntaxes.html#valid-date-string
    eleventyConfig.addFilter("readableDate", dateObj => {
        return DateTime.fromJSDate(dateObj, { zone: 'utc' }).toFormat("dd LLL yyyy");
    });
    eleventyConfig.addFilter('htmlDateString', (dateObj) => {
        return DateTime.fromJSDate(dateObj, { zone: 'utc' }).toFormat('yyyy-LL-dd');
    });

    // Override "posts" collection to sort by date
    eleventyConfig.addCollection("posts", (collection) => {
        return collection
            .getFilteredByGlob("src/content/posts/*.md")
            .sort((p1, p2) => p1.date - p2.date);
    });

    eleventyConfig.addCollection("gallery", (collection) => {
        return collection
            .getFilteredByTag("photography")
            .sort((p1, p2) => p1.date - p2.date);
    });

    eleventyConfig.addCollection("postTags", function (collectionAPI) {
        let collection = collectionAPI.getFilteredByGlob("src/content/posts/*.md");
        let resultArrays = {};
        collection.forEach((item) => {
            item.data.tags.forEach((tag) => {
                if (!resultArrays[tag]) { 
                    resultArrays[tag] = []; 
                }
                resultArrays[tag].push(item);
            });
        });
        return Object.entries(resultArrays).map((r) => ({tag: r[0], count: r[1].length})).sort((a, b) => b.count - a.count);
    });

    eleventyConfig.setFrontMatterParsingOptions({
		excerpt: true,
	});

    // Customize Markdown library and settings:
    let markdownLibrary = markdownIt({
        html: true,
        breaks: true,
        linkify: true,
        modifyToken: function (token, env) {
            switch (token.type) {
                // case 'image':
                //     const src = token.attrObj.src;
                //     if (src.startsWith("../assets")) {
                //         token.attrObj.src = src.replace("../assets", "/assets");
                //     }
                //     break;
                case 'link_open':
                    const href = token.attrObj.href;
                    if (href && (!href.includes('jeeb.uk') &&
                        !href.includes('jupiter:8080') &&
                        !href.startsWith('./') &&
                        !href.startsWith('../') &&
                        !href.startsWith('/') &&
                        !href.startsWith('#'))) {
                            token.attrObj.target = '_blank';
                            token.attrObj.rel = 'noopener noreferrer';
                    }
                    break;
            }
        }
    })
    .use(require('markdown-it-modify-token'));
    eleventyConfig.setLibrary("md", markdownLibrary);

    eleventyConfig.addFilter("markdownToHtml", str => {
        let markdownLibrary = markdownIt({
            html: true,
            breaks: false,
        });
        markdownLibrary.linkify.set({});
        markdownLibrary.disable('link');
        return markdownLibrary.renderInline(str).replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
    });

    eleventyConfig.addFilter("markdownToImagesOnly", str => {
        let markdownLibrary = markdownIt({
            html: true,
            breaks: false,
        });
        markdownLibrary.linkify.set({});
        markdownLibrary.disable('link');
        const inline = markdownLibrary.renderInline(str).replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
        return inline.match(/<img\s+[^>]*?>/g);
    });

    return {
        templateFormats: [
            "md",
            "njk",
            "html",
            "liquid"
        ],
        markdownTemplateEngine: "njk",
        htmlTemplateEngine: "njk",
        pathPrefix: "/",
        dir: {
            input: "src",
            includes: "_includes",
            data: "_data",
            output: "output"
        }
    };
};
