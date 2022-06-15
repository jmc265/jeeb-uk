function slugifyPart(str) {
    const from = "ãàáäâẽèéëêìíïîõòóöôùúüûñç·/_,:;"
    const to = "aaaaaeeeeeiiiiooooouuuunc------"

    const newText = str.split('').map(
        (letter, i) => letter.replace(new RegExp(from.charAt(i), 'g'), to.charAt(i)))

    return newText
        .toString()                     // Cast to string
        .toLowerCase()                  // Convert the string to lowercase letters
        .trim()                         // Remove whitespace from both sides of a string
        .replace(/\s+/g, '-')           // Replace spaces with -
        .replace(/&/g, '-y-')           // Replace & with 'and'
        .replace(/[^\w\-]+/g, '')       // Remove all non-word chars
        .replace(/\-\-+/g, '-');        // Replace multiple - with single -
}

module.exports = function(path) {
    let link = path;
    link = link.replaceAll("%20", " ")
    link = link.replaceAll("&", "and");
    link = link.replace(".md", "")
    link = link.replace("/Index", "");
    link = link.split("/").map(part => {
        if (part === "." || part === "..") {
            return part;
        }
        return slugifyPart(part);
    }).join("/");
    return link;
};