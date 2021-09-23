{ comma-repo, nixpkgsPath, pkgs }:
let
  commaPrewrapped = import comma-repo { inherit pkgs; };
in
pkgs.writeShellScriptBin "," ''
  export NIX_PATH="nixpkgs=${nixpkgsPath}"
  exec "${commaPrewrapped}/bin/comma" "$@"
''
