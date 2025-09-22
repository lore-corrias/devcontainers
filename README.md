# Devcontainers

These are my opinionated containers that I use when I have to do some development.
You can find the sources at https://github.com/lore-corrias/devcontainers

## CTFBox

CTFBox is a container that I use to solve CTF challenges (tipically web security ones).
It runs on Arch (btw) to have a wide variety of available packages, including `burpsuite`.

The intended way to run this is to use the `ctfbox.ini` configuration for [distrobox](https://distrobox.it),
which takes care of forwarding useful packages (like docker and podman).

You can bring the container up with the following command:

```sh
distrobox-assemble create --file ctfbox.ini
```

and enter the container with


```sh
distrobox enter ctfbox
```

## Devcontainer

This is my base `debian` image that incorporates some useful tools for devcontainers,
which I usually run with [Devpod](https://devpod.sh). Some of the tools installed are:

- Neovim
- Zsh
- Tmux
- fd-find
- ripgrep
- and others
