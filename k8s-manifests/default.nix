{ pkgs }:
let
  ccat = "${pkgs.ccrypt}/bin/ccat";
  kubectl = "${pkgs.kubectl}/bin/kubectl";

  applyBaseManifests =
    pkgs.writeShellScriptBin "apply_base_manifests" ''
      if [ -z "$SECRETS_PASSPHRASE" ]; then
        echo "please set env var SECRETS_PASSPHRASE"
        exit 1
      fi

      ${ccat} -E SECRETS_PASSPHRASE -c ${./dev_env_secrets.yaml.cpt} | ${kubectl} apply -f -
    '';

  applyDeploymentManifestsWithImage = { imageNameWithTag, deploymentEnv }:
    let
      deploymentManifest = import ./dev-env-deployment.nix { inherit pkgs imageNameWithTag deploymentEnv; };
    in
    pkgs.writeShellScriptBin "apply_deployment_manifests" ''
      ${applyBaseManifests}/bin/apply_base_manifests
      ${kubectl} apply -f ${deploymentManifest}
    '';
in
{
  inherit applyDeploymentManifestsWithImage;
}
