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

          prodImage = imageBuilder "latest";
          stagingImage = imageBuilder "staging";
        in
        {
          defaultPackage.${system} = stagingImage;
          packages.${system} = {
            staging = stagingImage;
            latest = prodImage;
          };
        };
    in
    outputs' "x86_64-linux";
}
