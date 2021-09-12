{ pkgs, nixpkgsPath, tag }: { deploymentEnv }:
let
  user = "root";
  home = "root";
  certPath = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  inherit (pkgs) buildPackages dockerTools lib;

  configFiles = import ./config-files.nix { inherit pkgs nixpkgsPath user home; };
  codeServerExts = import ./extensions.nix { inherit pkgs; };

  restartPodScript = pkgs.writeShellScriptBin "restart_pod" ''
    exec "${pkgs.kubectl}/bin/kubectl" -n dev delete pod $(hostname)
  '';

  entrypoint = pkgs.writeShellScriptBin "entrypoint" ''
    chmod a+rwx /tmp
    mkdir -p /usr/bin
    ln -s ${pkgs.coreutils}/bin/env /usr/bin/env

    mkdir -p /${home}/.ssh /${home}/.local/share/code-server
    cp /tmp/secrets/ssh/id_rsa /${home}/.ssh
    chmod 400 /${home}/.ssh/id_rsa

    ln -s ${codeServerExts}/extensions /${home}/.local/share/code-server/extensions
    ${pkgs.code-server}/bin/code-server --disable-telemetry --bind-addr 0.0.0.0:8080 /${home}/project
  '';

  pkgsContents = [
    pkgs.bashInteractive
    pkgs.coreutils
    pkgs.curl
    pkgs.direnv
    pkgs.dnsutils
    pkgs.git
    pkgs.gnugrep
    pkgs.gnused
    pkgs.htop
    pkgs.inetutils
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.less
    pkgs.nixFlakes
    pkgs.nix-direnv
    pkgs.nixos-generators
    pkgs.nmon
    pkgs.openssh
    pkgs.ps
    pkgs.vim
    pkgs.which
  ];

  otherContents = [
    restartPodScript
  ];

  contents = pkgsContents ++ otherContents ++ configFiles;
  imageName = "nexus.lan:5000/dev-env";

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
    ];
  };

  passthru = {
    inherit deploymentEnv;
    imageNameWithTag = "${imageName}:${dev-env-image.imageTag}";
  };
in
lib.extendDerivation true passthru dev-env-image
