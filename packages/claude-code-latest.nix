{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, refresh_claude_code_latest
}:

let
  # version and hashes are rewritten in place by refresh_claude_code_latest
  # (mods/pog/refresh.nix); CI runs it nightly. To pin: --version X
  version = "2.1.286";

  # Native bun-compiled binary from the per-platform npm package; the main
  # @anthropic-ai/claude-code package is just a JS launcher around these.
  # Hashes are the registry's own dist.integrity values.
  platformMap = {
    aarch64-darwin = {
      npmPlatform = "darwin-arm64";
      hash = "sha512-QlU1+S7cNO1BKzlMJGRR/ZqdsP6c3+QAA2u9EX7dTO6HUo1/RAenn/q+mlyX60MZzTZOjPkAmTt77eYrH1IAwg==";
    };
    x86_64-linux = {
      npmPlatform = "linux-x64";
      hash = "sha512-PnVL8ZCEev3IexLeOc9/QRfqRDUZRgnsaMLdpjlBN0VaieeTrf7mZ2JJi29ue2KAqHvq6SsOadU5G/shnFE4MA==";
    };
  };

  platform = platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-${platform.npmPlatform}/-/claude-code-${platform.npmPlatform}-${version}.tgz";
    inherit (platform) hash;
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

  passthru = {
    updateScript = refresh_claude_code_latest;
    # read by the update script, so the platform list lives in one place
    npmPlatforms = lib.mapAttrs (_: p: p.npmPlatform) platformMap;
  };

  meta = {
    description = "Claude Code CLI - AI-powered coding assistant by Anthropic";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = lib.attrNames platformMap;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
