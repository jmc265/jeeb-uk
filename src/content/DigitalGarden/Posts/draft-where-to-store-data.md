---
title:  "Where to store data/state in a react application" 
permalink: react-where-to-store/
layout: post
draft: true 
tags: 
  - posts
  - programming
  - terraform
  - react 
  - state management 
  - redux 
  - next.js
  - context providers 
  - cache 
---

There are lots of ways to store data and state in a react based application, and the differences in developer experience and performance are stark. Understanding these differences and selecting the best mechanism is very important for a medium to large sized app.

The places we can choose from include:

- Context providers
- API cache library (E.g. React-query, SWR)
- `useState`
- State management library (E.g. Redux, zustand, jotai)


## Context Providers

Context providers, are a great way to avoid prop drilling some static (or rarely mutated) data down a sub tree of your component hierarchy. 

As context providers tie together the rendering of all components that rely on it (and all of its non-memoized children) it is best to make sure the data does not mutate very often as you can quickly end up with a lot of unnecessary re-renders. 

## API cache library



## `useState`


## State management library

