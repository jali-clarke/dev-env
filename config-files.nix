{ pkgs, nixpkgsPath, user, home, cacheHostname }:
let
  usersFiles = import ./users.nix { inherit pkgs user home; };

  uploadToCache = pkgs.writeShellScriptBin "upload_to_cache" ''
    set -eu
    set -f # disable globbing
    export IFS=' '

    DESTINATION="ssh://root@${cacheHostname}"

    echo "Uploading signed paths to $DESTINATION - " $OUT_PATHS
    exec ${pkgs.nixUnstable}/bin/nix copy --to "$DESTINATION" $OUT_PATHS
  '';
in
usersFiles ++ [
  (
    pkgs.writeTextDir "etc/nix/nix.conf" ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
      keep-derivations = true
      keep-outputs = true
      post-build-hook = ${uploadToCache}/bin/upload_to_cache
      sandbox = false
      secret-key-files = /tmp/secrets/cache_signing_key/signing_key
      substituters = ssh://root@${cacheHostname}?priority=10 https://cache.nixos.org?priority=100
    ''
  )
  (
    pkgs.writeTextDir "etc/protocols" ''
      ip      0       IP              # internet protocol, pseudo protocol number
      icmp    1       ICMP            # internet control message protocol
      igmp    2       IGMP            # Internet Group Management
    ''
  )
  (
    import ./bashrc.nix { inherit pkgs home; }
  )
  (
    pkgs.writeTextDir "${home}/.config/nix/registry.json" ''
      {
        "flakes": [
          {
            "from": {
              "id": "nixpkgs",
              "type": "indirect"
            },
            "to": {
              "path": "${nixpkgsPath}",
              "type": "path"
            }
          }
        ],
        "version": 2
      }
    ''
  )
  (
    pkgs.writeTextDir "${home}/.direnvrc" ''
      source /share/nix-direnv/direnvrc
    ''
  )
  (
    pkgs.writeTextDir "${home}/.ghci" ''
      :set prompt "\ESC[1;32m\x03BB> \ESC[m"
      :set prompt-cont "\ESC[1;32m > \ESC[m"
    ''
  )
  (
    pkgs.writeTextDir "${home}/.gitconfig" ''
      [user]
        email = jinnah.ali-clarke@outlook.com
        name = jali-clarke
      [pull]
        rebase = false
      [init]
        defaultBranch = master
      [alias]
        autosquash = !GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash
        branchc = branch --show-current
        brancho = !echo origin/$(git branchc)
        diffc = !git diff $1~1
        diffo = !git diff $(git brancho)
        fixup = commit --fixup
        fixupa = commit -a --fixup
        pushf = push --force-with-lease
        pushuo = !git push -u origin $(git branchc)
    ''
  )
  (
    pkgs.writeTextDir "${home}/.local/share/code-server/User/settings.json" ''
      {
        "files.autoSave": "afterDelay",
        "workbench.editor.enablePreview": false,
        "explorer.openEditors.visible": 0,
        "files.eol": "\n",
        "terminal.integrated.shell.linux": "${pkgs.bashInteractive}/bin/bash",
        "terminal.integrated.shellArgs.linux": [
          "--login"
        ],
        "workbench.colorTheme": "Default Dark+",
        "workbench.startupEditor": "none",
        "[haskell]": {
          "editor.tabSize": 2
        },
        "[nix]": {
          "editor.tabSize": 2
        }
      }
    ''
  )
  (
    pkgs.writeTextDir "${home}/.profile" ''
      . "/${home}/.bashrc"
    ''
  )
]
