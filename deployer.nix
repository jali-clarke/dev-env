{ pkgs, dev-env-image }:
let
  git = "${pkgs.git}/bin/git";
  artifactPusher = import ./artifact-pusher.nix { inherit pkgs dev-env-image; };
  image-patch-json-2902 = pkgs.writeText "image-patch.json6902.yaml" ''
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: "${dev-env-image.imageNameWithTag}"
  '';

  patchPathInRepo = "k8s-manifests/overlay/image-patch.json6902.yaml";
in
pkgs.writeShellScriptBin "deploy_dev_env" ''
  ${artifactPusher}/bin/push_artifact
  rm ${patchPathInRepo}
  cp ${image-patch-json-2902} ${patchPathInRepo}
  ${git} add ${patchPathInRepo}
  ${git} commit -m "updated image to ${dev-env-image.imageNameWithTag}"
  ${git} push
''
