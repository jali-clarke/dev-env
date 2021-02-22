{pkgs}: {dev-env-streamed}:
pkgs.writeScriptBin "deploy_artifact" ''
  #!${pkgs.runtimeShell} -xe

  ${dev-env-streamed} | ${pkgs.docker}/bin/docker load
  ${pkgs.docker}/bin/docker push ${dev-env-streamed.imageNameWithTag}
''
