{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.homelab-config.url = "github:jali-clarke/homelab-config/weedle-known-good";

  inputs.comma.url = "github:jali-clarke/comma/flakify";
  inputs.dotfiles.url = "github:jali-clarke/dotfiles";
  inputs.dotfiles.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, homelab-config, comma, dotfiles }:
    let
      nixpkgsPath = "${nixpkgs}";
      cacheHostname = "cache.nix-cache";

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
          builtImage = assert self.sourceInfo ? rev; import ./dev-env.nix {
            inherit pkgs nixpkgsPath cacheHostname;
            tag = self.sourceInfo.rev;
            homeManagerConfig = { username, homeDirectory }:
              dotfiles.lib.builtHomeManagerModule {
                inherit system username homeDirectory;
                configuration = import ./home.nix;
              };
          };
        in
        {
          defaultPackage.${system} = self.packages.${system}.deployer;

          packages.${system}.deployer = import ./deployer.nix {
            inherit pkgs;
            dev-env-image = builtImage;
          };

          devShell.${system} = pkgs.mkShell {
            name = "dev-env-dev-shell";
            buildInputs = [
              pkgs.diffutils
              pkgs.kubectl
              pkgs.nixpkgs-fmt
            ];
          };
        };
    in
    outputs' "x86_64-linux";
}
