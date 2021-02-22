{pkgs}: {imageNameWithTag, deploymentEnv}:
let
  volumesAndNamespaceManifest = import ./dev-env-volumes.nix {inherit pkgs;};
  deploymentManifest = import ./dev-env-deployment.nix {inherit pkgs imageNameWithTag deploymentEnv;};

  ccat = "${pkgs.ccrypt}/bin/ccat";
  kubectl = "${pkgs.kubectl}/bin/kubectl";
in
pkgs.writeScriptBin "apply_manifests" ''
  #!${pkgs.runtimeShell} -xe

  if [ -z "$SECRETS_PASSPHRASE" ]; then
    echo "please set env var SECRETS_PASSPHRASE"
    exit 1
  fi

  ${ccat} -E SECRETS_PASSPHRASE -c ${./dev_env_secrets.yaml.cpt} | ${kubectl} apply -f -

  ${kubectl} apply -f ${volumesAndNamespaceManifest}
  ${kubectl} apply -f ${deploymentManifest}
''
