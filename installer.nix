{pkgs}: {dev-env-streamed}:
let
  artifactDeployer = import ./artifact-deployer.nix {inherit pkgs;};
  manifestsApplyer = import ./k8s-manifests {inherit pkgs;};
in
pkgs.writeScriptBin "install_dev_env" ''
  #!${pkgs.runtimeShell} -xe

  ${artifactDeployer {inherit dev-env-streamed;}}/bin/deploy_artifact
  ${manifestsApplyer {inherit (dev-env-streamed) imageNameWithTag deploymentEnv;}}/bin/apply_manifests
''
