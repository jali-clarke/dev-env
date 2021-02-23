{pkgs}: {dev-env-image}:
pkgs.writeScriptBin "deploy_artifact" ''
  #!${pkgs.runtimeShell} -xe

  ${pkgs.docker}/bin/docker load -i ${dev-env-image}
  ${pkgs.docker}/bin/docker push ${dev-env-image.imageNameWithTag}
''
