{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "2.1.219";

  # Native bun-compiled binary from the per-platform npm package; the main
  # @anthropic-ai/claude-code package is just a JS launcher around these.
  # To bump: update version, then refresh each hash with
  #   nix-prefetch-url https://registry.npmjs.org/@anthropic-ai/claude-code-<platform>/-/claude-code-<platform>-<version>.tgz
  platformMap = {
    "aarch64-darwin" = {
      npmPlatform = "darwin-arm64";
      sha256 = "1nlbk5sizc728kgmv6zbbjbkkld9d5pq7z485h9g70n9dbjs381n";
    };
    "x86_64-darwin" = {
      npmPlatform = "darwin-x64";
      sha256 = "1j2dih38md11pcagi720ci3p0b2fq5v7izj2gsp0sgq6g4y8y3wp";
    };
    "x86_64-linux" = {
      npmPlatform = "linux-x64";
      sha256 = "19vs17hal26nafjx1gnajwjkkc65z7w0hqlw12kf2kcdkks8iajg";
    };
    "aarch64-linux" = {
      npmPlatform = "linux-arm64";
      sha256 = "05gbw122s5nyyazq63rbaazbvqzlgxz4kj33x9ssr4cby1qycjng";
    };
  };

  platform = platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-${platform.npmPlatform}/-/claude-code-${platform.npmPlatform}-${version}.tgz";
    inherit (platform) sha256;
  };
in
stdenv.mkDerivation {
  pname = "claude-code-latest";
  inherit version src;

  sourceRoot = "package";

  # bun-compiled single-file executable: strip destroys the embedded JS
  # bundle, leaving a bare bun runtime that ignores claude's CLI args
  dontStrip = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 claude $out/bin/claude
    runHook postInstall
  '';

  meta = {
    description = "Claude Code CLI - AI-powered coding assistant by Anthropic";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
