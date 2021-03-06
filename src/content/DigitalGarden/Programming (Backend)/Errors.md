Error messages should be made up of:
- Context - What led to the error?
- Error - What is the issue?
- Mitigation - How to overcome the error?

Other rules:
- Be consistent in usage of concepts/terms and verbs
- Interfaces should raise error codes/throw exceptions
- Raise an exception OR log an error. Don't do both (dual logging will occur)
- Fail early - when the first issue arises

## Links
- [What's in a good error message?](https://www.morling.dev/blog/whats-in-a-good-error-message/)