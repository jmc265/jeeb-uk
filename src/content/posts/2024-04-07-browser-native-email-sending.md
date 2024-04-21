---
title:  "What if Web Browsers were able to send emails?" 
permalink: browse-native-email-send/
layout: post
tags:
  - programming
  - webapp
  - javascript
  - email
  - smtp
---

If a Web Browser was aware of it's user's email account (and how to use the account to send email), then contact forms on the internet would be lot better.

---

Currently, contact forms on the web ask for the user's email address and a message to send (at the very least). Then there will either be a form submit with a network POST request made with the data, or the javascript running on the page will have to do an XHR request to send the message to recipient. There will have to be some backend service running in order to receive this data, and do something with it, whether that is to store it in a DB, send it onwards to another service or to directly send an email. This service should protect itself in order to stop malicious usage of the message-sending capability. 

But what if the Browser was able to send an email on behalf of the browser user? Well then the Javascript running in the client would have a nice simple interface, something like:

```javascript
const [error, success] = await window.sendUserMessage('site-owner@example.com', 'Message Title', 'Message Body');
```

(You could also imagine how this might be extend to allow the user to select local files to send as attachments).

The Browser would be able to interact with the user in a native way, allowing them to consent to sending the email, and even allowing them a choice between multiple accounts to send it from. The user would no longer have to insert their email address into the contact form, as the Browser would know this detail for them. The Browser would also have to know how to actually send that email and so it would need to be authenticated for access to the user's email, probably via SMTP. 

It would also mean that there no longer needs to be a backend of any type. The Browser would do all the work. Essentially it means less surface area for web-app developers to protect.