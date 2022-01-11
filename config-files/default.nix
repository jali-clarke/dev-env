{ pkgs, nixpkgsPath, user, home, cacheHostname, homeManagerConfigWithUser }:
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

  dotfiles = homeManagerConfigWithUser.config.dotfiles.config;

  simpleFileFromDotfile = dotfile:
    let
      stripRoot = p: builtins.substring 1 (builtins.stringLength p) p;
    in
    pkgs.writeTextDir (stripRoot dotfile.target) dotfile.contents;

  simpleDotfiles = map simpleFileFromDotfile [
    dotfiles."direnv/direnvrc"
    dotfiles."git/config"
    dotfiles.".zshenv"
  ];
in
usersFiles ++ simpleDotfiles ++ [
  (
    pkgs.writeTextDir "${home}/.local/share/code-server/User/settings.json" dotfiles."vscode/settings".contents
  )
  (
    let
      zshrcDotfile = dotfiles.".zshrc";
    in
    pkgs.runCommandLocal ".zshrc" { } ''
      # zshrcDotfile.target is guaranteed to start with a `/`
      path=$out${zshrcDotfile.target}
      mkdir -p "$(dirname "$path")"

      # remove session vars source - it's not relevant in the container
      ${pkgs.gnused}/bin/sed '/\.nix-profile\/etc\/profile\.d\/hm-session-vars\.sh/d' "${zshrcDotfile.file}" > "$path"
    ''
  )
  (
    pkgs.writeTextDir "${home}/.profile" ''
      . "/${home}/.zshrc"
    ''
  )
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
    pkgs.writeTextDir "${home}/.ghci" ''
      :set prompt "\ESC[1;32m\x03BB> \ESC[m"
      :set prompt-cont "\ESC[1;32m > \ESC[m"
    ''
  )
]
