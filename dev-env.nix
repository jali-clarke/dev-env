{ pkgs, tag, cacheHostname, homeManagerConfig }:
let
  inherit (pkgs) buildPackages dockerTools lib;

  user = "root";
  home = "root";
  certPath = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  homeManagerConfigWithUser = homeManagerConfig {
    username = user;
    homeDirectory = "/${home}";
  };

  configFiles = import ./config-files { inherit pkgs user home homeManagerConfigWithUser; };
  codeServerExts = import ./extensions.nix { inherit pkgs homeManagerConfigWithUser; };

  restartPodScript = pkgs.writeShellScriptBin "restart_pod" ''
    exec "${pkgs.kubectl}/bin/kubectl" -n dev delete pod/$(hostname)
  '';

  uploadToCache = pkgs.writeShellScriptBin "upload_to_cache" ''
    set -eu
    set -f # disable globbing
    export IFS=' '

    DESTINATION="ssh://root@${cacheHostname}"

    echo "Uploading signed paths to $DESTINATION - " $OUT_PATHS
    exec ${pkgs.nix}/bin/nix copy --to "$DESTINATION" $OUT_PATHS
  '';

  entrypoint = pkgs.writeShellScriptBin "entrypoint" ''
    mkdir -p /tmp
    chmod a+rwx /tmp

    mkdir -p /usr/bin
    ln -s ${pkgs.coreutils}/bin/env /usr/bin/env

    mkdir -p /${home}/.ssh

    mkdir -p /${home}/.local/share/code-server
    ln -s ${codeServerExts}/extensions /${home}/.local/share/code-server/extensions

    exec ${pkgs.code-server}/bin/code-server --disable-telemetry --bind-addr 0.0.0.0:8080 $EXTRA_ARGS /${home}/project
  '';

  pkgsContents = [
    pkgs.bash
    pkgs.comma
    pkgs.coreutils
    pkgs.curl
    pkgs.diffutils
    pkgs.direnv
    pkgs.dnsutils
    pkgs.findutils
    pkgs.fzf
    pkgs.git
    pkgs.git-lfs
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gzip
    pkgs.htop
    pkgs.inetutils
    pkgs.jq
    pkgs.k9s
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.less
    pkgs.man
    pkgs.nix
    pkgs.nix-direnv
    pkgs.nix-tree
    pkgs.nixos-generators
    pkgs.nmon
    pkgs.oh-my-zsh
    pkgs.openssh
    pkgs.ps
    pkgs.vim
    pkgs.which
    pkgs.zsh
  ];

  otherContents = [
    restartPodScript
    uploadToCache
  ];

  contents = pkgsContents ++ otherContents ++ configFiles;
  imageName = "docker.jali-clarke.ca/dev-env";

  dev-env-image = dockerTools.buildLayeredImageWithNixDb {
    name = imageName;

    inherit contents tag;

    config.Cmd = [ "${entrypoint}/bin/entrypoint" ];
    config.Env = [
      "USER=${user}"
      "HOME=/${home}"
      "SSL_CERT_FILE=${certPath}"
      "SYSTEM_CERTIFICATE_PATH=${certPath}"
      "NIX_PATH=nixpkgs=${pkgs.path}"
      "NIX_CONF_DIR=/nix-conf"
      "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive"
    ];
  };

  passthru = {
    imageNameWithTag = "${imageName}:${dev-env-image.imageTag}";
  };
in
lib.extendDerivation true passthru dev-env-image
