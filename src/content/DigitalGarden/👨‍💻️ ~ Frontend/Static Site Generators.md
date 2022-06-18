I first used [Jekyll](https://jekyllrb.com/) to create james.cx. I later moved on to [Hugo](https://gohugo.io/) briefly as that seemed to have a large community, before finally settling on [11ty](https://www.11ty.dev/) 11ty is Javascript based (presumably Typescript would also be an option with some config) and is incredibly configurable. Writing plugins and additional features for the static generation was a breeze. It does need to update it's syntax though as it feels quite old to have to do a `module.exports = ...` in order to configure the generator. Supporting Typescript and perhaps changing the syntax/configuration to be similar to [Express](https://expressjs.com/) would make it really nice. 

## Links
- [Overview of some options](https://byteofdev.com/posts/static-site-generators/)
- [11ty](https://www.11ty.dev/)
- [Island Architecture](https://jasonformat.com/islands-architecture/)
- [Astro - Modern SSG with web frameworks like React/Vue & Typescript](https://github.com/withastro/astro)
- [Server-side rendering at scale](https://engineeringblog.yelp.com/2022/02/server-side-rendering-at-scale.html)
- [11ty plugin for iterating over links and adding `target=_blank` to external links](https://franknoirot.co/posts/external-links-markdown-plugin/)
- ["The absurd complexity of server-side rendering" - Opinions on SSR](https://gist.github.com/Widdershin/98fd4f0e416e8eb2906d11fd1da62984) ([HN](https://news.ycombinator.com/item?id=31087795))
- [A gentle introduction to SSR](https://hire.jonasgalvez.com.br/2022/apr/30/a-gentle-introduction-to-ssr/)