{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, refresh_claude_code_latest
}:

let
  # version and hashes are rewritten in place by refresh_claude_code_latest
  # (mods/pog/refresh.nix); CI runs it nightly. To pin: --version X
  version = "2.1.317";

  # Native bun-compiled binary from the per-platform npm package; the main
  # @anthropic-ai/claude-code package is just a JS launcher around these.
  # Hashes are the registry's own dist.integrity values.
  platformMap = {
    aarch64-darwin = {
      npmPlatform = "darwin-arm64";
      hash = "sha512-Xnf9K4aGBuoYaODmEZ0o/lRvuYUCv2ZIDP+AXv15WVITryGgrsSA7CFL7KH+43kC6WhK8i6oysF6EbGdgBW4Aw==";
    };
    x86_64-linux = {
      npmPlatform = "linux-x64";
      hash = "sha512-u19fYJ4llqi+dAGAj6P1BNu/CRSe0rv4O8Mv/5SQPU5oXCYmUssbJgrBI6rWbIFRAE3YcLCzKlwdHbzlSXBlSA==";
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
