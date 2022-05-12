const { DateTime } = require("luxon");
const fs = require("fs");
const pluginRss = require("@11ty/eleventy-plugin-rss");
const pluginSyntaxHighlight = require("@11ty/eleventy-plugin-syntaxhighlight");
const embedYouTube = require("eleventy-plugin-youtube-embed");
const eleventyNavigationPlugin = require("@11ty/eleventy-navigation");
const markdownIt = require("markdown-it");
const markdownItGithubHeadings = require("markdown-it-github-headings")
const slugify = require("./src/eleventy/slugify");

module.exports = function (eleventyConfig) {
    eleventyConfig.setUseGitIgnore(false);
    eleventyConfig.addPassthroughCopy({
        "src/content/Digital Garden/assets": "assets",
        "src/_includes/css": "assets/css",
        "src/_includes/js": "assets/js",
        "src/_includes/img": "assets/img",
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
    eleventyConfig.addPlugin(eleventyNavigationPlugin);

    // Alias `layout: post` to `layout: layouts/post.njk`
    eleventyConfig.addLayoutAlias("post", "layouts/post.njk");

    eleventyConfig.addFilter("readableDate", dateObj => {
        return DateTime.fromJSDate(dateObj, { zone: 'utc' }).toFormat("dd LLL yyyy");
    });

    // https://html.spec.whatwg.org/multipage/common-microsyntaxes.html#valid-date-string
    eleventyConfig.addFilter('htmlDateString', (dateObj) => {
        return DateTime.fromJSDate(dateObj, { zone: 'utc' }).toFormat('yyyy-LL-dd');
    });

    // Override "posts" collection to not show drafts
    eleventyConfig.addCollection("posts", (collection) => {
        return collection
            .getFilteredByGlob("src/content/**/*.md")
            .filter((post) => post.data.isBlog === true)
            .filter((post) => post.date <= new Date() && !post.data.draft);
    });

    // Create Digital Garden collection
    eleventyConfig.addCollection("digitalGarden", (collection) => {
        return collection
            .getFilteredByGlob("src/content/**/*.md")
            .filter((post) => post.data.draft != true);
    });

    // Customize Markdown library and settings:
    let markdownLibrary = markdownIt({
        html: true,
        breaks: true,
        linkify: true,
        modifyToken: function (token, env) {
            switch (token.type) {
                case 'image':
                    const src = token.attrObj.src;
                    if (src.startsWith("../assets")) {
                        token.attrObj.src = src.replace("../assets", "/assets");
                    }
                    break;
                case 'link_open':
                    const href = token.attrObj.href;
                    if (href && (!href.includes('jeeb.uk') &&
                        !href.includes('jupiter:8082') &&
                        !href.startsWith('./') &&
                        !href.startsWith('../') &&
                        !href.startsWith('/') &&
                        !href.startsWith('#'))) {
                            token.attrObj.target = '_blank';
                            token.attrObj.rel = 'noopener noreferrer';
                    }
                    if (href.endsWith(".md")) {
                        const slugifiedHref = slugify(href);
                        token.attrObj.href = `/${slugifiedHref.replaceAll("../", "")}`;
                    }
                    break;
            }
        }
    })
        .use(require('markdown-it-modify-token'))
        .use(markdownItGithubHeadings, {
            className: "heading-anchor apply-svg-filter",
            prefixHeadingIds: false
        });
    eleventyConfig.setLibrary("md", markdownLibrary);

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
