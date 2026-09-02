final: prev:
(x: { hax = x; }) (
  with prev;
  with lib;
  lib // rec {
    inherit (stdenv) isLinux isDarwin isAarch64;
    isM1 = isDarwin && isAarch64;
    attrIf = check: name: if check then name else null;
    words = splitString " ";

    ssh = {
      github = ''
        Host github.com
          User git
          Hostname github.com
          PreferredAuthentications publickey
      '';
    };
    writeBashBinChecked = name: text:
      stdenv.mkDerivation {
        inherit name text;
        dontUnpack = true;
        passAsFile = "text";
        nativeBuildInputs = [ shellcheck ];
        installPhase = ''
          mkdir -p $out/bin
          echo '#!/bin/bash' > $out/bin/${name}
          cat $textPath >> $out/bin/${name}
          chmod +x $out/bin/${name}
          shellcheck $out/bin/${name}
        '';
      };
  }
)
