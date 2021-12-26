{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.homelab-config.url = "github:jali-clarke/homelab-config/weedle-known-good";
  inputs.comma.url = "github:jali-clarke/comma/flakify";

  outputs = { self, nixpkgs, comma, homelab-config }:
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
              comma.overlay
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
              pkgs.ccrypt
              pkgs.kubectl
              pkgs.nixpkgs-fmt
            ];
          };
        };
    in
    outputs' "x86_64-linux";
}
