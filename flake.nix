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
          artifactDeployer = import ./artifact-deployer.nix {inherit pkgs;};
        in
        {
          defaultPackage.${system} = self.packages.${system}.stagingArtifactDeployer;
          packages.${system} = {
            stagingImage = imageBuilder {deploymentEnv = "staging";};
            prodImage = imageBuilder {deploymentEnv = "prod";};
            stagingArtifactDeployer = artifactDeployer self.packages.${system}.stagingImage;
            prodArtifactDeployer = artifactDeployer self.packages.${system}.prodImage;
          };
        };
    in
    outputs' "x86_64-linux";
}
