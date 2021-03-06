# dev-env

my dev environment in my self-hosted cluster

## what this is

i have a k8s cluster at home and i'd like to have a persistent linux-y dev environment on it as my other machines are a windows desktop and a macbook pro.  this repo (powered by the almighty [nix](https://nixos.org/guides/how-nix-works.html)!) contains IasC for building and eventually deploying a containerized dev environment which takes the form of a [code-server](https://github.com/cdr/code-server) deployment along with some useful dev tools, languages, and system packages (see [dev-env.nix](./dev-env.nix)).  it used to be in a private monorepo but it's in a state where it can be publically available.

## how to build

### prerequisites

* nix with [flakes](https://nixos.wiki/wiki/Flakes) support
* an accessible docker registry `docker.lan:5000`
* a k8s cluster
* an nfs file server at `192.168.0.103` with appropriate shares set up
* appropriate credentials

### instructions

for a staging image i.e. testing out changes, do `nix run github:jali-clarke/dev-env#stagingInstaller`.  for a "prod" image, do `nix run github:jali-clarke/dev-env#prodInstaller`.

if you've cloned the repo locally and are dev-ing on it, you can do `nix run .#stagingInstaller` and `nix run .#prodInstaller` respectively.
