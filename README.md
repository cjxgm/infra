# infra: Arch Linux servers automation infrastructure for [cjprods.org]
[![Travis Build Status][build-badge]][travis-project]

[cjprods.org]: https://cjprods.org
[build-badge]: https://img.shields.io/travis/cjxgm/infra.svg?style=for-the-badge&logo=travis&maxAge=5
[travis-project]: https://travis-ci.org/cjxgm/infra

The goal is to automate the configuration of Arch Linux servers
at [cjprods.org].

- Utilize `systemd` to its full potential.
  - Socket activation
  - Generators (dynamic unit files and drop-ins)
  - Compartmentization (security sandboxing, `DynamicUser`, etc.)
  - Only requires a [Stateless System]
- Utilize `pacman` (`alpm`, Arch Linux Package Manager) to its full potential.
  - alpm hooks
- Use GitHub Release as an Arch Linux repository.
- Support for hiding secrets for certain situations (like passwords and keys).
- Reusable: Everyone can setup their own automation based on this project.
  - Keep as most things in plaintext as possible.
    Only sensitive parts (passwords, open ports, etc.) are encrypted.
  - Every encrypted file `secret-*` has a corresponding
    example plaintext file `example-secret-*`.

[Stateless System]: http://0pointer.net/blog/projects/stateless.html

## Setup a new server
```
# /etc/pacman.conf
[infra]
SigLevel = Optional TrustAll
Server = https://github.com/cjxgm/infra/releases/download/latest
```

Upload and install the private key package manually.

> **NOTE**: the `infra-private-key` from the GitHub Release repo is empty.

Now, `pacman -Syu`, then install any wanted packages.
All packages provided by this repo has a prefix of `infra-`.

## Setup git for accessing secrets
- Put the private key in `secret.pem`.
- Run `make setup`.
- After editing `secret-*` files, it's better (for now) to
  run `make unsetup` to cancel the effect
  so that rebasing won't conflict that much.

## About various keys
- The private key is used for encrypting the decryption key.
- The encrypted decryption key is `secret.key`.
- The decryption key (with the private key) is used to decrypting secrets.

