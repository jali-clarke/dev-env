{ pkgs, user, home }:
let
  passwd = pkgs.writeTextDir "etc/passwd" ''
    ${user}:x:0:0:${user}:/${home}:${pkgs.zsh}/bin/zsh
    nobody:x:65534:65534:nobody:/:/sbin/nologin
    nixbld1:x:30001:30000:Nix build user 1:/var/empty:/sbin/nologin
    nixbld2:x:30002:30000:Nix build user 2:/var/empty:/sbin/nologin
    nixbld3:x:30003:30000:Nix build user 3:/var/empty:/sbin/nologin
    nixbld4:x:30004:30000:Nix build user 4:/var/empty:/sbin/nologin
    nixbld5:x:30005:30000:Nix build user 5:/var/empty:/sbin/nologin
    nixbld6:x:30006:30000:Nix build user 6:/var/empty:/sbin/nologin
    nixbld7:x:30007:30000:Nix build user 7:/var/empty:/sbin/nologin
    nixbld8:x:30008:30000:Nix build user 8:/var/empty:/sbin/nologin
    nixbld9:x:30009:30000:Nix build user 9:/var/empty:/sbin/nologin
    nixbld10:x:30010:30000:Nix build user 10:/var/empty:/sbin/nologin
    nixbld11:x:30011:30000:Nix build user 11:/var/empty:/sbin/nologin
    nixbld12:x:30012:30000:Nix build user 12:/var/empty:/sbin/nologin
    nixbld13:x:30013:30000:Nix build user 13:/var/empty:/sbin/nologin
    nixbld14:x:30014:30000:Nix build user 14:/var/empty:/sbin/nologin
    nixbld15:x:30015:30000:Nix build user 15:/var/empty:/sbin/nologin
    nixbld16:x:30016:30000:Nix build user 16:/var/empty:/sbin/nologin
    nixbld17:x:30017:30000:Nix build user 17:/var/empty:/sbin/nologin
    nixbld18:x:30018:30000:Nix build user 18:/var/empty:/sbin/nologin
    nixbld19:x:30019:30000:Nix build user 19:/var/empty:/sbin/nologin
    nixbld20:x:30020:30000:Nix build user 20:/var/empty:/sbin/nologin
    nixbld21:x:30021:30000:Nix build user 21:/var/empty:/sbin/nologin
    nixbld22:x:30022:30000:Nix build user 22:/var/empty:/sbin/nologin
    nixbld23:x:30023:30000:Nix build user 23:/var/empty:/sbin/nologin
    nixbld24:x:30024:30000:Nix build user 24:/var/empty:/sbin/nologin
    nixbld25:x:30025:30000:Nix build user 25:/var/empty:/sbin/nologin
    nixbld26:x:30026:30000:Nix build user 26:/var/empty:/sbin/nologin
    nixbld27:x:30027:30000:Nix build user 27:/var/empty:/sbin/nologin
    nixbld28:x:30028:30000:Nix build user 28:/var/empty:/sbin/nologin
    nixbld29:x:30029:30000:Nix build user 29:/var/empty:/sbin/nologin
    nixbld30:x:30030:30000:Nix build user 30:/var/empty:/sbin/nologin
  '';

  shadow = pkgs.writeTextDir "etc/shadow" ''
    ${user}:!::0:::::
    nobody:!::0:::::
    nixbld1:!:18625:0:99999:7:::
    nixbld2:!:18625:0:99999:7:::
    nixbld3:!:18625:0:99999:7:::
    nixbld4:!:18625:0:99999:7:::
    nixbld5:!:18625:0:99999:7:::
    nixbld6:!:18625:0:99999:7:::
    nixbld7:!:18625:0:99999:7:::
    nixbld8:!:18625:0:99999:7:::
    nixbld9:!:18625:0:99999:7:::
    nixbld10:!:18625:0:99999:7:::
    nixbld11:!:18625:0:99999:7:::
    nixbld12:!:18625:0:99999:7:::
    nixbld13:!:18625:0:99999:7:::
    nixbld14:!:18625:0:99999:7:::
    nixbld15:!:18625:0:99999:7:::
    nixbld16:!:18625:0:99999:7:::
    nixbld17:!:18625:0:99999:7:::
    nixbld18:!:18625:0:99999:7:::
    nixbld19:!:18625:0:99999:7:::
    nixbld20:!:18625:0:99999:7:::
    nixbld21:!:18625:0:99999:7:::
    nixbld22:!:18625:0:99999:7:::
    nixbld23:!:18625:0:99999:7:::
    nixbld24:!:18625:0:99999:7:::
    nixbld25:!:18625:0:99999:7:::
    nixbld26:!:18625:0:99999:7:::
    nixbld27:!:18625:0:99999:7:::
    nixbld28:!:18625:0:99999:7:::
    nixbld29:!:18625:0:99999:7:::
    nixbld30:!:18625:0:99999:7:::
  '';

  group = pkgs.writeTextDir "etc/group" ''
    ${user}:x:0:${user}
    nogroup:x:65533:
    nobody:x:65534:
    nixbld:x:30000:nixbld1,nixbld2,nixbld3,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld30
  '';
in
[
  passwd
  shadow
  group
]
