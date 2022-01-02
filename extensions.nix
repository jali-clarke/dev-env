{ pkgs, homeManagerConfigWithUser }:
let
  codeServerExts = homeManagerConfigWithUser.config.programs.vscode.extensions;
  doLink = extDerivation: ''
    ln -s ${extDerivation}/share/vscode/extensions/${extDerivation.vscodeExtUniqueId} $out/extensions/${extDerivation.vscodeExtUniqueId}
  '';
in
pkgs.runCommand "dev-env-code-server-exts" { } ''
  mkdir -p $out/extensions
  ${pkgs.lib.concatMapStrings doLink codeServerExts}
''
