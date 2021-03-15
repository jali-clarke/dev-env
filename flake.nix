{
  inputs.homelab-config.url = "github:jali-clarke/homelab-config";

  outputs = {self, nixpkgs, homelab-config}:
    let
      nixpkgsPath = "${nixpkgs}";

      outputs' = system:
        let
          overlay = final: previous: {
            writeShellScriptBin = name: text:
              previous.writeScriptBin name ''
                #!${final.runtimeShell} -xe
                ${text}
              '';
          };

          pkgs = import nixpkgs {
            inherit system;

            overlays = [
              homelab-config.overlays.${system}
              overlay
            ];
          };

          imageBuilder = import ./dev-env.nix {inherit pkgs nixpkgsPath;};
          installer = import ./installer.nix {inherit pkgs;};
        in
        {
          defaultPackage.${system} = self.packages.${system}.stagingInstaller;

          packages.${system} = {
            stagingInstaller = installer {
              dev-env-image = imageBuilder {deploymentEnv = "staging";};
            };
            prodInstaller = installer {
              dev-env-image = imageBuilder {deploymentEnv = "prod";};
            };
          };

          devShell.${system} = pkgs.mkShell {
            name = "dev-env-dev-shell";
            buildInputs = [
              pkgs.kubectl
            ];
          };
        };
    in
    outputs' "x86_64-linux";
}
