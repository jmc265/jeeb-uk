---
title:  Typescript File Inheritance
permalink: typescript-file-inheritance/
layout: post
tags: 
  - posts
  - programming
  - typescript
---

I am not sure how useful this pattern is, but it has some interesting effects, especially when sharing code between projects. So let me give you a brief description of it and you can see where to apply it.

Imagine we are writing a simple Web App with a frontend, written in Typescript, and a Node backend, also written in Typescript. This is an excellent opportunity to share some code between the 2 projects. Let's say this simple webapp has a `User` entity that is passed back and forth between the frontend and the backend, and that the backend stores the `User` in a database. The database entry might have some additional properties, like `password` which we don't want to share with the frontend.

First, we are going to create a shared representation of a `RequestUser`. This interface will be used by both the front-end and the backend and it in a top-level folder called `shared`:

`shared/user.ts`

```typescript
interface RequestUser {
    name: string;
    email: string;
}
```

Then, in the `api` folder, we want to use the `RequestUser` interface, but add to it to store more items in the Database entry:

`api/user.ts`

```typescript
import * as User from "../shared/user.ts";

interface DatabaseUser extends RequestUser {
    password: string;
}
```

This all seems fine, but what happens when we want to use both `RequestUser` and `DatabaseUser` interfaces in our API handler, keeping in mind the [`import * as ...`](https://james.cx/typescript/2020/06/27/typescript-star-as.html) patten previously described?

`api/handler.ts`

```typescript
import * as User from "../shared/user.ts";
import * as ApiUser from "./user.ts";

export function handler(body: any) {
    const rqUser: User.RequestUser = body.user as User.RequestUser;
    const dbUser: ApiUser.DatabaseUser = {
        ...rqUser,
        "password": 'P@55word'
    }
}
```

We now have 2 name spaces, `ApiUser` and `User` to represent User type models. We can compress that down to 1 namespace, using the `export * from` pattern. If we look again at our API-specific model file, we can tell it to export everything from the shared model, essentially inheriting all the exported members from that file:

`api/user.ts`

```typescript
import * as User from "../shared/user.ts";
export * from "../shared/user.ts";
...
```

And then in our handler again, we can clear up some of the references:

`api/handler.ts`

```typescript
import * as User from "./user.ts";

export function handler(body: any) {
    const rqUser: User.RequestUser = body.user as User.RequestUser;
    const dbUser: User.DatabaseUser = {
        ...rqUser,
        "password": 'P@55word'
    }
}
```

We have one less import, and we can see that the `RequestUser` and `DatabaseUser` are very closely related as they both come from the same namespace. It is slightly cleaner code, and lets newcomers to our code read and scan it with ease.