{ pkgs, nixpkgsPath, user, home }:
let
  usersFiles = import ./users.nix { inherit pkgs user home; };
in
usersFiles ++ [
  (
    # keep trusted-public-keys in sync with the cache-signing-key secret
    pkgs.writeTextDir "etc/nix/nix.conf" ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
      keep-derivations = true
      keep-outputs = true
      sandbox = false
      substituters = ssh://root@dev-env-cache?priority=10 https://cache.nixos.org?priority=100
      trusted-public-keys = dev-env-cache:qvlzVFMLRIJkReizkn7KWNtjTHIPPA+PcP1T+V6HyWU= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
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
