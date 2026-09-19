{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, refresh_claude_code_latest
}:

let
  # version and hashes are rewritten in place by refresh_claude_code_latest
  # (mods/pog/refresh.nix); CI runs it nightly. To pin: --version X
  version = "2.1.278";

  # Native bun-compiled binary from the per-platform npm package; the main
  # @anthropic-ai/claude-code package is just a JS launcher around these.
  # Hashes are the registry's own dist.integrity values.
  platformMap = {
    aarch64-darwin = {
      npmPlatform = "darwin-arm64";
      hash = "sha512-Jgl//CpT1KR1N8uxAN0CmkFu3eESU7GYzPOwdGH1pCENysJqYgo2LwsIrTol+EequNMrTG3kkrNW9mIoS8eWLg==";
    };
    x86_64-linux = {
      npmPlatform = "linux-x64";
      hash = "sha512-q3r+5aLGAet1MGMkCH2xPsuIW9A40ws4zftURxhYwDenheCKvXc7Gr1jBwvEhYG8uQwgY3YsfNwnvIsh1Bjmeg==";
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
