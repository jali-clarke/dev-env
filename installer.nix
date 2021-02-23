{pkgs}: {dev-env-image}:
let
  artifactDeployer = import ./artifact-deployer.nix {inherit pkgs;};
  manifestsApplyer = import ./k8s-manifests {inherit pkgs;};
in
pkgs.writeShellScriptBin "install_dev_env" ''
  ${artifactDeployer {inherit dev-env-image;}}/bin/deploy_artifact
  ${manifestsApplyer {inherit (dev-env-image) imageNameWithTag deploymentEnv;}}/bin/apply_manifests
''
