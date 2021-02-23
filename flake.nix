{
  inputs.nixos-generators.url = "github:nix-community/nixos-generators";
  inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {self, nixpkgs, nixos-generators}:
    let
      nixpkgsPath = "${nixpkgs}";
      outputs' = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nixos-generate = nixos-generators.defaultPackage.${system};
          imageBuilder = import ./dev-env.nix {inherit pkgs nixpkgsPath nixos-generate;};
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
        };
    in
    outputs' "x86_64-linux";
}
