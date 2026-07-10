{ lib
, stdenv
, fetchurl
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sinch-cli";
  version = "0.5.0";

  # @sinch/cli on npm is only a Node launcher shim; the actual bun-compiled
  # executable ships in the per-platform package, so fetch that directly.
  # To bump: update version, then refresh the hash from
  #   curl -s https://registry.npmjs.org/@sinch%2fcli-darwin-arm64 | jq -r '.versions["<version>"].dist.integrity'
  src = fetchurl {
    url = "https://registry.npmjs.org/@sinch/cli-darwin-arm64/-/cli-darwin-arm64-${finalAttrs.version}.tgz";
    hash = "sha512-6ptZvnxr9Gu4Xx88DPRDqfZ8aRa6xI1ZxWxbcjlyv/wq/vOaycHzgextXHRBEPNxXtKo+Rzg1P8H/mZ/9sz9Jw==";
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
