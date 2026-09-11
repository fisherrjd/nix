{ lib
, stdenv
, fetchurl
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sinch-cli";
  version = "0.6.2";

  # @sinch/cli on npm is only a Node launcher shim; the actual bun-compiled
  # executable ships in the per-platform package, so fetch that directly.
  # To bump: update version, then refresh the hash from
  #   curl -s https://registry.npmjs.org/@sinch%2fcli-darwin-arm64 | jq -r '.versions["<version>"].dist.integrity'
  src = fetchurl {
    url = "https://registry.npmjs.org/@sinch/cli-darwin-arm64/-/cli-darwin-arm64-${finalAttrs.version}.tgz";
    hash = "sha512-2jGKsGJKzM8oCBVSWpAJyAMUFz9AMRDHHOePrU/C2H9lfClqedNJewkJu3Hd/4RjRUtC/jkwpjllgBGcWfXHIQ==";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/sinch $out/bin/sinch

    runHook postInstall
  '';

  meta = {
    description = "Sinch CLI (prebuilt binary from the npm registry)";
    homepage = "https://www.sinch.com/products/apis/voice/";
    license = lib.licenses.mit;
    mainProgram = "sinch";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
