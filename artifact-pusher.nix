{ pkgs, dev-env-image }:
let
  skopeoFlags = "--insecure-policy --tmpdir=/tmp";
in
pkgs.writeShellScriptBin "push_artifact" ''
  ${pkgs.skopeo}/bin/skopeo copy ${skopeoFlags} docker-archive:${dev-env-image} docker://${dev-env-image.imageNameWithTag}
''
