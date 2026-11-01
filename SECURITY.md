# Security policy

## Supported versions

Fixes land on the latest minor release only.

| Version | Supported |
|---|---|
| 0.1.x | Yes |
| Older | No |

## Reporting a vulnerability

`husk_sdk` reads `husk.yaml`, xcframework property lists and AAR archives,
writes build files that Xcode, CocoaPods and Gradle execute, and copies
vendor binaries, often in CI. A crafted spec, property list or archive that
makes it hang, crash in an exploitable way, read or write outside the
project, or inject code into a generated build file is a security problem.

Please report privately: open this repository's **Security** tab and choose
**Report a vulnerability**. This creates a private advisory that only you and
the maintainer can see.

Do **not** open a public issue, pull request or discussion for a
vulnerability.

Useful things to include:

- the package version, `dart --version` and the host OS
- the exact command you ran
- a minimal project or file that reproduces it (invented, never a real
  vendor SDK or a real project's configuration)
- what an attacker could achieve, and any fix you have in mind

## What to expect

You will usually get a first reply within a week. Once the issue is
confirmed, a fix is prepared in the private advisory, released, and the
advisory is published with credit to you unless you prefer otherwise.
