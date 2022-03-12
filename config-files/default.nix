{ pkgs, user, home, homeManagerConfigWithUser }:
let
  usersFiles = import ./users.nix { inherit pkgs user home; };

  dotfiles = homeManagerConfigWithUser.config.dotfiles.config;

  simpleFileFromDotfile = filename:
    let
      dotfile = dotfiles.${filename};
      stripRoot = p: builtins.substring 1 (builtins.stringLength p) p;
    in
    pkgs.writeTextDir (stripRoot dotfile.target) dotfile.contents;

  zshDotfile = filename:
    let
      zshDotfile = dotfiles.${filename};
    in
      pkgs.runCommandLocal filename { } ''
        # zshDotfile is guaranteed to start with a `/`
        path=$out${zshDotfile.target}
        mkdir -p "$(dirname "$path")"

        # remove session vars source - it's not relevant in the container
        ${pkgs.gnused}/bin/sed '/\.nix-profile\/etc\/profile\.d\/hm-session-vars\.sh/d' "${zshDotfile.file}" > "$path"
      '';

  simpleDotfiles = map simpleFileFromDotfile [ "direnv/direnvrc" "git/config" "nix/registry" ];

  zshDotfiles = map zshDotfile [ ".zshrc" ".zshenv" ];
in
usersFiles ++ simpleDotfiles ++ zshDotfiles ++ [
  (
    pkgs.writeTextDir "${home}/.local/share/code-server/User/settings.json" dotfiles."vscode/settings".contents
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
