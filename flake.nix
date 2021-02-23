{
  inputs.nixos-generators.url = "github:nix-community/nixos-generators";
  inputs.nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {self, nixpkgs, nixos-generators}:
    let
      nixpkgsPath = "${nixpkgs}";

      outputs' = system:
        let
          overlay = final: previous: {
            nixos-generators = nixos-generators.defaultPackage.${system};
            writeShellScriptBin = name: text:
              previous.writeScriptBin name ''
                #!${final.runtimeShell} -xe
                ${text}
              '';
          };

          pkgs = import nixpkgs {inherit system; overlays = [overlay];};
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
        };
    in
    outputs' "x86_64-linux";
}
