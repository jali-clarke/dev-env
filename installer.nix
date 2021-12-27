{ pkgs }: { dev-env-image }:
let
  artifactDeployer = import ./artifact-deployer.nix { inherit pkgs; };
in
pkgs.writeShellScriptBin "install_dev_env" ''
  ${artifactDeployer { inherit dev-env-image; }}/bin/deploy_artifact
''
