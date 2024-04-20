---
title:  "Typescript `import * as ...`"
permalink: typescript-import-star-as/
layout: post
tags:
  - programming
  - typescript
---

There is a very easy to use and simple pattern that can be used whilst importing files in Typescript. The main advantage of using this pattern is to increase the readability and scan-ability of code. And that pattern is `import * as ...`

---

It is especially useful when it is used with models, so let's have a look at a very simple model:

`user.ts`

```typescript
interface UserType {
    firstName: string;
    surname: string;
}

export function fromJson(input: any): UserType {
    return {
        firstName: input.firstName || "",
        surname: input.surname || ""
    }
}

export function getName(user: UserType): string {
    return `${user.firstName} ${user.surname}`;
}
```

If we don't use the `import *` syntax, we would have to import the 2 functions separately as follows:

```typescript
import {fromJson, getName} from 'user.ts';

const input = { /* some JSON */ }}
const object = fromJson(input);
console.log(getName(object));
```

The above is not particularly easily to scan. We get to the usage of `fromJson`, but as the reader we have to break our scan by either looking at the top of file to see where the function came from or use our IDE's intellisense to see what the type of `object` is. Furthermore, on the next line, the function name `getName` might not remain unique to `User`.

So, in order to make the code easier to scan and parse for others, we can user the `import * as` pattern:

```typescript
import * as User from 'user.ts';

const input = { /* some JSON */ }}
const object = User.fromJson(input);
console.log(User.getName(object));
```

From scanning this file, the reader can very quickly understand that the variable `object` is a `User` because the function `fromJson` is namespaced to that file. The `getName` call can now be disambiguated from a `getName` function that might exist on another type of object.

This pattern also works nicely for utils or helpers, as such:

```typescript
const user = db.getUser();
const user = cache.getUser();
const user = queue.getUser();
```
