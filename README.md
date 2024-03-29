# dev-env

my dev environment in my self-hosted cluster

## what this is

i have a k8s cluster at home and i'd like to have a persistent linux-y dev environment on it as my other machines are a windows desktop and a macbook pro.  this repo (powered by the almighty [nix](https://nixos.org/guides/how-nix-works.html)!) contains IasC for building and eventually deploying a containerized dev environment which takes the form of a [code-server](https://github.com/cdr/code-server) deployment along with some useful dev tools, languages, and system packages (see [dev-env.nix](./dev-env.nix)).  it used to be in a private monorepo but it's in a state where it can be publically available.

## how to build

### prerequisites

* nix with [flakes](https://nixos.wiki/wiki/Flakes) support
* an accessible container image registry `docker.jali-clarke.ca` (secured behind tls)
* a k8s cluster
* an nfs file server at `atlas.jali-clarke.ca` with appropriate shares set up
* appropriate secrets via hashicorp vault

### instructions

`nix run .` to build, push, and deploy (via argo-rollouts + argo cd)
