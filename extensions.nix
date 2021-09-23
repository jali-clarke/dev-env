{ pkgs }:
let
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;
  exts = pkgs.vscode-extensions;

  codeServerExts = [
    exts.bbenoist.Nix
    exts.justusadam.language-haskell
  ];
in
pkgs.runCommand "dev-env-code-server-exts" { } ''
    mkdir -p $out/extensions
    ${lib.concatMapStrings
  (extDerivation: ''
      ln -s ${extDerivation}/share/vscode/extensions/${extDerivation.vscodeExtUniqueId} $out/extensions/${extDerivation.vscodeExtUniqueId}
    '')
  codeServerExts}
''
