{pkgs}: {dev-env-image}:
let
  skopeoFlags = "--insecure-policy --dest-tls-verify=false --tmpdir=/tmp";
in
pkgs.writeScriptBin "deploy_artifact" ''
  #!${pkgs.runtimeShell} -xe
  ${pkgs.skopeo}/bin/skopeo copy ${skopeoFlags} docker-archive:${dev-env-image} docker://${dev-env-image.imageNameWithTag}
''
