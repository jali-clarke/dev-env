{ pkgs }:
let
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;

  codeServerExt = { extensionName, version, publisher, hash, galleryUrl ? "https://marketplace.visualstudio.com/_apis/public/gallery" }:
    let
      url = "${galleryUrl}/publishers/${publisher}/vsextensions/${extensionName}/${version}/vspackage";
      extDirName = lib.toLower "${publisher}.${extensionName}-${version}";
      extFileName = "${extDirName}.vsix";

      self = stdenv.mkDerivation {
        name = "code-server-ext.${extDirName}";
        nativeBuildInputs = [
          pkgs.cacert
          pkgs.wget
          pkgs.libarchive
        ];

        passthru = {
          inherit extDirName;
          extDirPath = "${self}/${extDirName}";
        };

        src = pkgs.fetchurl {
          inherit hash url;
          name = extFileName;
        };

        unpackPhase = ''
          bsdtar -xf $src
        '';

        dontBuild = true;

        installPhase = ''
          mkdir -p $out
          mv extension $out/${extDirName}
        '';
      };
    in
    self;

  codeServerExts = [
    (
      codeServerExt {
        extensionName = "Nix";
        version = "1.0.1";
        publisher = "bbenoist";
        hash = "sha256-+zoR6EupIkKiWOdcW8FxTaJbWjjZVE0G+mB6S5qAmEw=";
      }
    )
    (
      codeServerExt {
        extensionName = "language-haskell";
        version = "3.3.0";
        publisher = "justusadam";
        hash = "sha256-8lwbKJKG+pbbZxfwg9oDr15TM6Ed4eecAGXHTc7P9/w=";
      }
    )
    (
      codeServerExt {
        extensionName = "language-purescript";
        version = "0.2.4";
        publisher = "nwolverson";
        hash = "sha256-ZsHVDtNaqzSTzuyZ8dMKg9VSdNHis4g9HO7KMCmKzDI=";
      }
    )
  ];
in
pkgs.runCommand "dev-env-code-server-exts" { } ''
    mkdir -p $out/extensions
    ${lib.concatMapStrings
  (extDerivation: ''
      ln -s ${extDerivation.extDirPath} $out/extensions/${extDerivation.extDirName}
    '')
  codeServerExts}
''
