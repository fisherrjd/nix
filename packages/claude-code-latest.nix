{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "2.1.269";

  # Native bun-compiled binary from the per-platform npm package; the main
  # @anthropic-ai/claude-code package is just a JS launcher around these.
  # To bump: update version, then refresh each hash with
  #   nix-prefetch-url https://registry.npmjs.org/@anthropic-ai/claude-code-<platform>/-/claude-code-<platform>-<version>.tgz
  platformMap = {
    "aarch64-darwin" = {
      npmPlatform = "darwin-arm64";
      sha256 = "11kn12237jvz333axwmm0v1d5dx1h70d8h1bcpcnxpvfg79798zb";
    };
    "x86_64-darwin" = {
      npmPlatform = "darwin-x64";
      sha256 = "1hll09fmczxiwab64lq0jbd1m9pmyg7vil5y06gzwafyqzcxqfx0";
    };
    "x86_64-linux" = {
      npmPlatform = "linux-x64";
      sha256 = "sha256-AQJYZYq3oKoJ6pkssqMUaJ4lzkKFTFfWmT4xNglwOdU=";
    };
    "aarch64-linux" = {
      npmPlatform = "linux-arm64";
      sha256 = "15miyf0kb9y54mnw3pscwx2w1jy54apl72zl4drp1mggsc6da2ig";
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
    platforms = lib.attrNames platformMap;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
