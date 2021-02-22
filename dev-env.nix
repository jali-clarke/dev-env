{pkgs, nixpkgsPath, nixos-generate}: {deploymentEnv}:
let
  user = "root";
  home = "root";
  certPath = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  inherit (pkgs) buildPackages dockerTools lib;

  configFiles = import ./config-files.nix {inherit pkgs user home;};
  codeServerExts = import ./extensions.nix {inherit pkgs;};

  restartPodScript = pkgs.writeScriptBin "restart_pod" ''
    #!${pkgs.runtimeShell} -xe
    exec "${pkgs.kubectl}/bin/kubectl" -n dev delete pod $(hostname)
  '';

  entrypoint = pkgs.writeScriptBin "entrypoint" ''
    #!${pkgs.runtimeShell} -xe

    chmod a+rw /var/run/docker.sock
    chmod a+rwx /tmp

    mkdir -p /${home}/.ssh /${home}/.local/share/code-server
    cp /tmp/secrets/ssh/id_rsa /${home}/.ssh
    chmod 400 /${home}/.ssh/id_rsa

    ln -s ${codeServerExts}/extensions /${home}/.local/share/code-server/extensions
    ${pkgs.code-server}/bin/code-server --disable-telemetry --bind-addr 0.0.0.0:8080 /${home}/project
  '';

  pkgsContents = [
    pkgs.bashInteractive
    pkgs.coreutils
    pkgs.direnv
    pkgs.dnsutils
    pkgs.docker
    pkgs.git
    pkgs.gnugrep
    pkgs.htop
    pkgs.inetutils
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.less
    pkgs.nixFlakes
    pkgs.nix-direnv
    pkgs.nmon
    pkgs.openssh
    pkgs.ps
    pkgs.vim
    pkgs.which
  ];

  otherContents = [
    nixos-generate
    restartPodScript
  ];

  contents = pkgsContents ++ otherContents ++ configFiles;
  imageName = "docker.lan:5000/dev-env";

  dev-env-image = dockerTools.streamLayeredImage {
    name = imageName;
    tag = if deploymentEnv == "prod" then "latest" else deploymentEnv;

    inherit contents;

    # see https://github.com/NixOS/nixpkgs/blob/793e77d4e2b14dfa1cb914b4604031defd5ce0ab/pkgs/build-support/docker/default.nix#L42
    extraCommands = ''
      echo "Generating the nix database..."
      echo "Warning: only the database of the deepest Nix layer is loaded."
      echo "         If you want to use nix commands in the container, it would"
      echo "         be better to only have one layer that contains a nix store."
      export NIX_REMOTE=local?root=$PWD
      # A user is required by nix
      # https://github.com/NixOS/nix/blob/9348f9291e5d9e4ba3c4347ea1b235640f54fd79/src/libutil/util.cc#L478
      export USER=nobody
      ${buildPackages.nix}/bin/nix-store --load-db < ${pkgs.closureInfo {rootPaths = contents;}}/registration
      mkdir -p nix/var/nix/gcroots/docker/
      for i in ${lib.concatStringsSep " " contents}; do
      ln -s $i nix/var/nix/gcroots/docker/$(basename $i)
      done;
    '';

    config.Cmd = ["${entrypoint}/bin/entrypoint"];
    config.Env = [
      "USER=${user}"
      "HOME=/${home}"
      "SSL_CERT_FILE=${certPath}"
      "SYSTEM_CERTIFICATE_PATH=${certPath}"
      "NIX_PATH=nixpkgs=${nixpkgsPath}"
    ];
  };

  passthru = {
    imageNameWithTag = "${imageName}:${dev-env-image.imageTag}";
  };
in
lib.extendDerivation true passthru dev-env-image
