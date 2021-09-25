{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  inputs.homelab-config.url = "github:jali-clarke/homelab-config";

  inputs.comma-repo.url = "github:Shopify/comma";
  inputs.comma-repo.flake = false;

  outputs = { self, nixpkgs, comma-repo, homelab-config }:
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

            comma = import ./comma.nix { inherit comma-repo nixpkgsPath; pkgs = final; };
          };

          pkgs = import nixpkgs {
            inherit system;

            overlays = [
              homelab-config.overlays.${system}
              overlay
            ];
          };

          # assertion will fail if the source tree is not clean
          imageBuilder = assert self.sourceInfo ? rev; import ./dev-env.nix { inherit pkgs nixpkgsPath; tag = self.sourceInfo.rev; };
          installer = import ./installer.nix { inherit pkgs; };
        in
        {
          defaultPackage.${system} = self.packages.${system}.stagingInstaller;

          packages.${system} = {
            stagingInstaller = installer {
              dev-env-image = imageBuilder { deploymentEnv = "staging"; };
            };
            prodInstaller = installer {
              dev-env-image = imageBuilder { deploymentEnv = "prod"; };
            };
          };

          devShell.${system} = pkgs.mkShell {
            name = "dev-env-dev-shell";
            buildInputs = [
              pkgs.kubectl
              pkgs.nixpkgs-fmt
            ];
          };
        };
    in
    outputs' "x86_64-linux";
}
