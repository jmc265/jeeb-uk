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


