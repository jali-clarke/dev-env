{pkgs}: {imageNameWithTag, deploymentEnv}:
let
  volumesAndNamespaceManifest = import ./dev-env-volumes.nix {inherit pkgs;};
  deploymentManifest = import ./dev-env-deployment.nix {inherit pkgs imageNameWithTag deploymentEnv;};
in
pkgs.writeScriptBin "apply_manifests" ''
  #!${pkgs.runtimeShell} -xe

  ${pkgs.kubectl}/bin/kubectl apply -f ${volumesAndNamespaceManifest}
  ${pkgs.kubectl}/bin/kubectl apply -f ${deploymentManifest}
''
