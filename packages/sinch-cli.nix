{ lib
, stdenv
, fetchurl
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sinch-cli";
  version = "0.5.3";

  # @sinch/cli on npm is only a Node launcher shim; the actual bun-compiled
  # executable ships in the per-platform package, so fetch that directly.
  # To bump: update version, then refresh the hash from
  #   curl -s https://registry.npmjs.org/@sinch%2fcli-darwin-arm64 | jq -r '.versions["<version>"].dist.integrity'
  src = fetchurl {
    url = "https://registry.npmjs.org/@sinch/cli-darwin-arm64/-/cli-darwin-arm64-${finalAttrs.version}.tgz";
    hash = "sha512-PoPeaqwG9yh7byzZgcdl+zqgfeKXREFx42EaGYCYQ7xXlyTWUivQ4q5RDkqqdb8HM4c07ic8FL20QYq/wVSAaQ==";
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
