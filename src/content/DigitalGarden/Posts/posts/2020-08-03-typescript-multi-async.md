---
title:  Typescript Multi Async Interface
permalink: typescript-multi-async-interface/
layout: post
tags:
  - programming
  - typescript
---

I recently had to write a Javascript library which was going to be used in multiple different contexts by lots of different people. The purpose of the library was to supply a stream of updating values. Internally to the library, [RxJS](https://github.com/ReactiveX/rxjs) is used as it excellently models streams of updating values. However, the interface to the library should not expose the inner workings.

---

So, I wanted to allow the consumer of the library to access the values in a number of ways:

## Usage

### Promises

The standard way of supplying asynchronous values. It is commonly used and with `async/await` the code is very readable:

```typescript
const currentValue = await lib.getValue();
```

The problem with this is, you can only get one value, you won't receive any further updates to the value. So, we can also support the next access method:

### Event Emitter

This will allow the consumer to subscribe to updates in the value and the syntax would be as follows:

```typescript
let currentValue;
lib.getValue()
   .onNew((value) => currentValue = value);
```

### Synchronous

I also wanted to allow the users of the library to synchronously obtain the latest as well as all previous values when they were unable to use async or event emitters:

```typescript
const currentValue = lib.getValue().latest();
const previousValues = lib.getValue().all();
```

## Implementation

We can see above that the `getValue()` function has some interesting properties. It returns something which can be listened to like a promise, but it also returns an object which has other methods on it for accessing the values. So what does this object look like? Well here is a Typescript interface describing the object that `getValue()` returns:

```typescript
interface AsyncAccessor<T> extends PromiseLike<T> {
    onNew(listener: (value: T) => void): void;
    latest(): T;
    all(): T[];
}
```

And using RxJS, the implementation of this class is fairly simple:

```typescript
class ValueAccessor<T> implements AsyncAccessor<T> {
    private _previousValues: T[] = [];

    constructor(private _valueStream: Observable<T>) {
        _valueSteam.subscribe(v => this._previousValues.push(v));
    }

    public getLatest(): T {
        return this._previousValues[this._previousValues.length-1];
    }

    public getAll(): T[] {
        return this._previousValues;
    }

    public onNew(listener: (value: T) => void) {
        this._valueSteam.subscribe(value => listener(value));
    }

    public then<TResult1 = T, TResult2 = never>(onfulfilled?: (value: T) => TResult1 | PromiseLike<TResult1>, onrejected?: (reason: any) => TResult2 | PromiseLike<TResult2>): PromiseLike<TResult1 | TResult2> {
        const previousValue = this.getLatest();
        if (previousValue) {
            return Promise.resolve(previousValue)
                        .then(onfulfilled, onrejected);
        }
        return this._valueSteam
                    .pipe(first())
                    .toPromise()
                    .then(onfulfilled, onrejected);
    }
}
```

And that's it. We now have a value accessor that can be used in a number of different values by a consumer to the library.