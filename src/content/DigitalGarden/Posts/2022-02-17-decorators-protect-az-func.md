---
title:  "Protecting endpoints with Typescript Method Decorators"
permalink: typescript-method-decorators/
layout: post
tags: 
  - posts
  - programming
  - typescript
  - backend
  - api
  - nodejs
  - serverless
---

Typescript allows for an excellent language feature called [Method Decorators](https://www.typescriptlang.org/docs/handbook/decorators.html#method-decorators). They are similar to annotations in Java and can be used to wrap or edit existing methods with new functionality. Below is an example of using Decorators to add some common functionality to endpoints, including authentication, validation and error handling.

The first decorator we will look at is validating that the incoming requests match our expectations, and return a Bad Request (HTTP 400), if not. The actual validation of the objects will be done using [joi](https://www.npmjs.com/package/joi).

We will first take a look at how we use the decorator to protect our endpoint:

```typescript
@ValidateBody({
    name: Joi.string().required()
})
async httpHandler(request): Promise<string> {
    return `Hello ${request.body.name}`;
}
```

When we use `request.body.name` in the httpHandler, we know that the variable is defined and has a value because of the validation decorator. But what does the decorator implementation look like?

```typescript
export function ValidateBody<R>(bodySchema: ObjectSchema<B>) {
    return <T>(target: object, name: string, descriptor: TypedPropertyDescriptor<T>): TypedPropertyDescriptor<T> => {
        const originalMethod = descriptor.value;
        descriptor.value = async (request) => {
            const result = bodySchema.validate(request.body);
            if (result.error) {
                throw new HttpError(HttpStatusCodes.BAD_REQUEST, result.error.message);
            }
            return await originalMethod.apply(this, request);
        };
        return descriptor;
    };
}
```

The decorator first stores a reference to the `originalMethod` so that we can later call it if the validations pass. The method is then overwritten with the lambda function inside the decorator. The lambda validates the body object and throws an error if the validation fails. (The `HttpError` object is caught in another decorator which is defined below.) If the validation succeeds, the `originalMethod` is called with a `.apply()` call and the return is passed back to the caller.

This validation can be extended to validate not just the body but also the query parameters, path parameters or http headers.

The next decorator we have is a HTTP basic authentication guard:

```typescript
@ValidateBasicAuth(process.env.basicAuthUsername, process.env.basicAuthPassword)
async httpHandler(request): Promise<string> {
    return `Authenticated Endpoint`;
}
```

And the definition of the decorator:

```typescript
export function ValidateBasicAuth(username: string, password: string) {
    return <T>(target: object, name: string, descriptor: TypedPropertyDescriptor<T>): TypedPropertyDescriptor<T> => {
        const originalMethod = descriptor.value;
        descriptor.value = async (request) => {
            if (!request.headers.authorization || request.headers.authorization.indexOf('Basic ') === -1) {
                throw new HttpError(HttpStatusCodes.UNAUTHORIZED);
            }

            // verify auth credentials
            const base64Credentials =  request.headers.authorization.split(' ')[1];
            const credentials = Buffer.from(base64Credentials, 'base64').toString('ascii');
            const [requestUsername, requestPassword] = credentials.split(':');
            if (username !== requestUsername || password !== requestPassword) {
                throw new HttpError(HttpStatusCodes.UNAUTHORIZED);
            }
            return await originalMethod.apply(this, request);
        };
        return descriptor;
    };
}
```

The decorator is very similar to the request validation decorator in that it checks a condition and throws an exception if the condition fails. In this case, the condition is a username and password check.

Finally, let's deal with the `HttpError` exceptions we have thrown. We want to catch these exceptions and transform them into HTTP responses that is returned to the caller:

```typescript
@HttpErrorHandler
async httpHandler(): Promise<string> {
    throw new HttpError(HttpStatusCodes.NOT_IMPLEMENTED);
    return null;
}
```

The `HttpErrorHandler` decorator is defined as:

```typescript
export function HttpErrorHandler<T>(target: object, name: string, descriptor: TypedPropertyDescriptor<T>): TypedPropertyDescriptor<T> {
    const originalMethod = descriptor.value;
    descriptor.value = async (request) => {
        try {
            const result = await originalMethod.apply(this, request);
            return result;
        } catch (e) {
            if (e instanceof HttpError) {
                const httpError = e as HttpError;
                return {
                    code: e.code,
                    body: {
                        message: e.message ?? null
                    }
                };
            }
            return {
                code: HttpStatusCodes.INTERNAL_SERVER_ERROR
            };
        }
    };
    return descriptor;
}
```

The decorator calls the original method in a try/catch block and caches any uncaught exceptions. If the exception is of type `HttpError`, it transforms it into a Http response with the status code that was thrown. If it is any other exception, we return a generic "Internal Server Error" response.

These decorators can be re-used throughout the whole codebase and removes a whole load of boiler plate which is ordinarily part of the Http Handler. They also make the code very easy to scan.
