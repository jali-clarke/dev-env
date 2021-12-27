{ pkgs, dev-env-image }:
let
  git = "${pkgs.git}/bin/git";
  artifactPusher = import ./artifact-pusher.nix { inherit pkgs dev-env-image; };
  image-patch-json-2902 = pkgs.writeText "image-patch.json6902.yaml" ''
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: "${dev-env-image.imageNameWithTag}"
  '';

  homelab-config-path = "/tmp/homelab-config-cloned";
  patchPathInRepo = "k8s/dev/overlay/image-patch.json6902.yaml";
in
pkgs.writeShellScriptBin "deploy_dev_env" ''
  ${artifactPusher}/bin/push_artifact

  rm -rf ${homelab-config-path}
  ${git} clone git@github.com:jali-clarke/homelab-config ${homelab-config-path}

  pushd ${homelab-config-path}
  ${git} checkout master
  rm ${patchPathInRepo}
  cp ${image-patch-json-2902} ${patchPathInRepo}
  ${git} add ${patchPathInRepo}
  ${git} commit -m "updated image to ${dev-env-image.imageNameWithTag}"
  ${git} push
  popd
''
