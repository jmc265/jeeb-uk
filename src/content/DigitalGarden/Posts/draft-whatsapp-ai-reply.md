---
title:  "WhatsApp AI Reply" 
permalink: whatsapp-ai-reply/
layout: post
draft: true 
tags: 
  - posts
  - programming
  - node
  - typescript
  - whatsapp
  - openai
  - chatgpt
  - bot
---

Wouldn't it be great to have ChatGPT auto-reply to some of your WhatsApp messages on your behalf? Well with a combination of the (unoffical) [WhatsApp client library](https://wwebjs.dev/) and [OpenAI client library](https://github.com/openai/openai-node) we can.

> INSERT VIDEO

We can do all this in under a 100 lines of code.

> **TLDR:** 
> ```shell
> docker run \
>   -e SELF_CONTACT_ID=xxxxx@c.us \
>   -e OPEN_AI_API_KEY=${OPEN_AI_API_KEY} \
>   -e OPEN_AI_MODEL_KEY='gpt-4-1106-preview' \
>   -e OPEN_AI_SYSTEM_PROMPT='You are an assistant who expands an emoji response to a message into a full text response' \
>   -v ./whatsapp-auth:/mnt/auth-data \
>   jmc265/whatsapp-ai-reply
> ```
> 
> Full source code: https://github.com/jmc265/whatsapp-ai-reply

First, let's get some initialisation code down to get the WhatsApp client library connected to your WhatsApp account. The below code will also store the auth information to `/mnt/auth-data` so that we can restart the process and still remain connected:

```typescript
import qrcode from 'qrcode-terminal';
import { Client, LocalAuth } from 'whatsapp-web.js';

const whatsAppClient = new Client({
  authStrategy: new LocalAuth({
    dataPath: '/mnt/auth-data'
  }),
  puppeteer: {
    args: ['--no-sandbox'],
  }
});

whatsAppClient.on('qr', qr => {
  qrcode.generate(qr, { small: true });
});

whatsAppClient.on('ready', () => {
  console.log('WhatsApp AI Reply is ready');
});

whatsAppClient.initialize();
```

Next we need to listen to reaction events. We only care about events that:
- Are sent by ourselves
- Are reactions to text-based messages (not images, audio etc.)

```typescript
whatsAppClient.on('message_reaction', async (whatsAppReaction) => {
  if (whatsAppReaction.senderId !== 'xxxxxx@c.us') {
    return;
  }
  if (!whatsAppReaction.reaction || whatsAppReaction.reaction === '') {
    return;
  }
  const whatsAppMessage = await whatsAppClient.getMessageById(whatsAppReaction.msgId._serialized);
  if (whatsAppMessage.type !== MessageTypes.TEXT) {
    return;
  }
  ...
});
```

Lastly, let's ask GPT4 for a response to the message and send it back:

```typescript
const chatCompletion = await openai.chat.completions.create({
  messages: [
    { role: 'system', content: 'You are an assistant who expands an emoji response to a message into a full text response' },
    { role: 'user', content: whatsAppMessage.body },
    { role: 'user', content: whatsAppReaction.reaction }
  ],
  model: 'gpt-4-1106-preview',
});
if (chatCompletion.choices[0].message.content) {
  await whatsAppMessage.reply(chatCompletion.choices[0].message.content);
}
```

And that's all the code we need!

We can wrap this up in a [Dockerfile](https://github.com/jmc265/whatsapp-ai-reply/blob/main/Dockerfile) and also use [Docker Compose](https://github.com/jmc265/whatsapp-ai-reply/blob/main/compose.yml) if we want.