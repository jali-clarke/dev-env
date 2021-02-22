{pkgs}: dev-env-streamed:
pkgs.writeScriptBin "artifact-deploy" ''
  #!${pkgs.runtimeShell} -xe

  ${dev-env-streamed} | ${pkgs.docker}/bin/docker load
  ${pkgs.docker}/bin/docker tag ${dev-env-streamed.imageNameWithTag} ${dev-env-streamed.imageNameWithDeploymentEnv}
  ${pkgs.docker}/bin/docker push ${dev-env-streamed.imageNameWithDeploymentEnv}
''
