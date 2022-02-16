{ pkgs, user, home, homeManagerConfigWithUser }:
let
  usersFiles = import ./users.nix { inherit pkgs user home; };

  dotfiles = homeManagerConfigWithUser.config.dotfiles.config;

  simpleFileFromDotfile = dotfile:
    let
      stripRoot = p: builtins.substring 1 (builtins.stringLength p) p;
    in
    pkgs.writeTextDir (stripRoot dotfile.target) dotfile.contents;

  simpleDotfiles = map simpleFileFromDotfile [
    dotfiles."direnv/direnvrc"
    dotfiles."git/config"
    dotfiles."nix/registry"
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
    pkgs.writeTextDir "etc/protocols" ''
      ip      0       IP              # internet protocol, pseudo protocol number
      icmp    1       ICMP            # internet control message protocol
      igmp    2       IGMP            # Internet Group Management
    ''
  )
  (
    pkgs.writeTextDir "${home}/.ghci" ''
      :set prompt "\ESC[1;32m\x03BB> \ESC[m"
      :set prompt-cont "\ESC[1;32m > \ESC[m"
    ''
  )
  (
    pkgs.writeTextDir "${home}/.ssh/config" ''
      StrictHostKeyChecking accept-new
      Host *
        IdentityFile /secrets/ssh/id_dev_env
    ''
  )
]
