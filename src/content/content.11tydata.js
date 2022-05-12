const path = require("path");
const fs = require("fs");
const slugify = require("../eleventy/slugify");

function isIndex(filePath) {
    return filePath.name === "Index";
}

function getPageTitle(data, filePath) {
    if (data.title) {
        return data.title;
    }
    if (isIndex(filePath)) {
        return getImmediateDirectory(filePath);
    }
    return filePath.name;
}

function getImmediateDirectory(filePath) {
    return filePath.dir.split(path.sep).at(-1);
}

function getOrder(data, filePath) {
    if (data && data.eleventyNavigation && data.eleventyNavigation.order) {
        return data.eleventyNavigation.order;
    }
    let directory;
    let searchParam;
    if (isIndex(filePath)) {
        directory = filePath.dir.split(path.sep).slice(0, -1).join(path.sep);
        searchParam = getImmediateDirectory(filePath);
    } else {
        directory = filePath.dir;
        searchParam = filePath.name + filePath.ext;
    }
    const directoryListing = fs.readdirSync(directory);
    return directoryListing.findIndex((elm) => elm === searchParam);
}

module.exports = function(c) {
    return {
        "layout": "layouts/post.njk",
        "showDate": false,
        "showTitle": true,
        "showBreadcrumbs": true,
        "isDigitalGarden": true,
        "eleventyComputed": {
           "title": data => getPageTitle(data, path.parse(data.page.inputPath)),
           "showChildren": data => isIndex(path.parse(data.page.inputPath)),
           "eleventyNavigation": data => {
               const filePath = path.parse(data.page.inputPath);
                return {
                    "key": isIndex(filePath) ? filePath.dir : data.page.inputPath,
                    "parent": isIndex(filePath) ? "DigitalGarden" : filePath.dir,
                    "title": getPageTitle(data, filePath),
                    "order": getOrder(data, filePath)
                }
           },
           "permalink": data => slugify(data.page.filePathStem).replace("/content", "").replace("/digitalgarden", "") + "/index.html"
        }
    }
}