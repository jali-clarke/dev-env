{ pkgs, nixpkgsPath, tag, cacheHostname, homeManagerConfig }:
let
  inherit (pkgs) buildPackages dockerTools lib;

  user = "root";
  home = "root";
  certPath = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  homeManagerConfigWithUser = homeManagerConfig {
    username = user;
    homeDirectory = "/${home}";
  };

  configFiles = import ./config-files { inherit pkgs nixpkgsPath user home cacheHostname homeManagerConfigWithUser; };
  codeServerExts = import ./extensions.nix { inherit pkgs homeManagerConfigWithUser; };

  restartPodScript = pkgs.writeShellScriptBin "restart_pod" ''
    exec "${pkgs.kubectl}/bin/kubectl" -n dev delete pod/$(hostname)
  '';

  entrypoint = pkgs.writeShellScriptBin "entrypoint" ''
    chmod a+rwx /tmp
    mkdir -p /usr/bin
    ln -s ${pkgs.coreutils}/bin/env /usr/bin/env

    mkdir -p /${home}/.ssh /${home}/.local/share/code-server
    cp /tmp/secrets/ssh/id_rsa /${home}/.ssh
    chmod 400 /${home}/.ssh/id_rsa
    echo -n "${cacheHostname} " >> /${home}/.ssh/known_hosts
    cat /tmp/secrets/cache_ssh_host_key/ssh_host_rsa_key.pub >> /${home}/.ssh/known_hosts
    chmod 600 /${home}/.ssh/known_hosts

    ln -s ${codeServerExts}/extensions /${home}/.local/share/code-server/extensions
    exec ${pkgs.code-server}/bin/code-server --disable-telemetry --bind-addr 0.0.0.0:8080 $EXTRA_ARGS /${home}/project
  '';

  pkgsContents = [
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
    pkgs.k9s
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.less
    pkgs.man
    pkgs.nixFlakes
    pkgs.nix-direnv
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
  ];

  contents = pkgsContents ++ otherContents ++ configFiles;
  imageName = "nexus.jali-clarke.ca:5000/dev-env";

  dev-env-image = dockerTools.buildLayeredImageWithNixDb {
    name = imageName;

    inherit contents tag;

    config.Cmd = [ "${entrypoint}/bin/entrypoint" ];
    config.Env = [
      "USER=${user}"
      "HOME=/${home}"
      "SSL_CERT_FILE=${certPath}"
      "SYSTEM_CERTIFICATE_PATH=${certPath}"
      "NIX_PATH=nixpkgs=${nixpkgsPath}"
      "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive"
    ];
  };

  passthru = {
    imageNameWithTag = "${imageName}:${dev-env-image.imageTag}";
  };
in
lib.extendDerivation true passthru dev-env-image
