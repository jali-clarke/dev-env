{pkgs}:
let
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;

  codeServerExt = {extensionName, version, publisher, galleryUrl ? "https://marketplace.visualstudio.com/_apis/public/gallery"}:
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

        src = url;

        unpackPhase = ''
          wget -O ${extFileName} $src
          bsdtar -xf ${extFileName}
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
      }
    )
    (
      codeServerExt {
        extensionName = "language-haskell";
        version = "3.3.0";
        publisher = "justusadam";
      }
    )
    (
      codeServerExt {
        extensionName = "language-purescript";
        version = "0.2.4";
        publisher = "nwolverson";
      }
    )
  ];
in
pkgs.runCommand "dev-env-code-server-exts" {} ''
  mkdir -p $out/extensions
  ${lib.concatMapStrings (extDerivation: ''
    ln -s ${extDerivation.extDirPath} $out/extensions/${extDerivation.extDirName}
  '') codeServerExts}
''
