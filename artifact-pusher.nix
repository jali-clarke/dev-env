{ pkgs, dev-env-image }:
let
  skopeoFlags = "--insecure-policy --dest-tls-verify=false --tmpdir=/tmp";
in
pkgs.writeShellScriptBin "push_artifact" ''
  ${pkgs.skopeo}/bin/skopeo copy ${skopeoFlags} docker-archive:${dev-env-image} docker://${dev-env-image.imageNameWithTag}
''
