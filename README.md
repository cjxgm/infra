# infra: Arch Linux servers automation infrastructure for cjprods.org
[![Travis Build Status](https://img.shields.io/travis/cjxgm/infra.svg?style=for-the-badge&logo=travis&maxAge=5)](https://travis-ci.org/cjxgm/infra)

The goal is to automate the management of servers at [cjprods.org](https://cjprods.org).

- Utilize `systemd` to its full potential.
  - Socket Activation
  - Compartmentization (security sandboxing, `DynamicUser`, etc.)
  - Only requires a [Stateless System](http://0pointer.net/blog/projects/stateless.html)
- Use GitHub Release as an Arch Linux repository.
- Support for hiding secrets for certain situations (like passwords and keys).

## Setup a Server
```
# /etc/pacman.conf
[infra]
SigLevel = Optional TrustAll
Server = https://github.com/cjxgm/infra/releases/download/latest
```

Upload the private key package (NOTE: the `infra-private-key` from the repo is empty)
and install it manually.

Install wanted packages, then `systemctl kexec` to reboot (only required the first time, or you can start services on your own).

## Setup Git for Accessing Secrets
Put the private key in `secret.pem`. Run `make setup`.
You may also run `make unsetup` to cancel the effect.

The private key is used for encrypting the decryption key.
The encrypted decryption key is `secret.key`.
The decryption key (with the private key) is used to decrypting secrets.

