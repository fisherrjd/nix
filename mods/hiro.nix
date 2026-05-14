# TODO: swap over to https://github.com/nix-community/bun2nix and bun entirely
final: prev:
let
  hiro-src = builtins.fetchGit {
    url = "git@gitlab.spectrumflow.net:spectrum-consulting/kiro/kiro-shared.git";
    rev = "ead657b5193f11fc2fd05b06379b0d4e47bff2bf";
    ref = "develop";
  };

  # Pre-built artifacts from local checkout.
  # Update workflow:
  #   1. cd ~/gitlab/kiro-shared && git pull
  #   2. HIRO_POSTINSTALL_SKIP=1 bun install && bun run build
  #   3. Update rev above
  #   4. hms

  hiro-out = builtins.path {
    path = /Users/P3175941/gitlab/kiro-shared/out;
    name = "hiro-out";
  };
  hiro-node-modules = builtins.path {
    path = /Users/P3175941/gitlab/kiro-shared/node_modules;
    name = "hiro-node-modules";
  };
in
{
  hiro = prev.stdenv.mkDerivation {
    pname = "hiro";
    version = "0.2.0";
    src = hiro-src;
    nativeBuildInputs = [ prev.bun prev.nodejs prev.makeWrapper ];

    buildPhase = ''
      export HOME=$TMPDIR
      cp -r ${hiro-node-modules} ./node_modules
      chmod -R u+w node_modules
      bun build/registry-index.ts
    '';

    installPhase = ''
      mkdir -p $out/lib/hiro $out/bin

      cp -r bin registry scripts package.json $out/lib/hiro/
      cp -r ${hiro-out} $out/lib/hiro/out
      cp -r ${hiro-node-modules} $out/lib/hiro/node_modules

      makeWrapper ${prev.nodejs}/bin/node $out/bin/hiro \
        --add-flags "$out/lib/hiro/bin/index.mjs" \
        --set KIRO_SHARED_ROOT "$out/lib/hiro"
    '';
  };
}
