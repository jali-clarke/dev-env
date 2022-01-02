{ pkgs, nixpkgsPath, user, home, cacheHostname, homeManagerConfig }:
let
  homeManagerConfigWithUser = homeManagerConfig {
    username = user;
    homeDirectory = "/${home}"; # `home` is not prefixed with `/` when pased in
  };

  usersFiles = import ./users.nix { inherit pkgs user home; };

  uploadToCache = pkgs.writeShellScriptBin "upload_to_cache" ''
    set -eu
    set -f # disable globbing
    export IFS=' '

    DESTINATION="ssh://root@${cacheHostname}"

    echo "Uploading signed paths to $DESTINATION - " $OUT_PATHS
    exec ${pkgs.nixUnstable}/bin/nix copy --to "$DESTINATION" $OUT_PATHS
  '';

  gitConfig = homeManagerConfigWithUser.config.xdg.configFile."git/config";
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
    pkgs.writeTextDir "${home}/${gitConfig.target}" gitConfig.text
  )
  (
    import ./vscode.nix { inherit pkgs home; }
  )
  (
    pkgs.writeTextDir "${home}/.profile" ''
      . "/${home}/.bashrc"
    ''
  )
]
