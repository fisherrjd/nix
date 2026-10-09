{ lib
, stdenvNoCC
, fetchurl
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "splash";
  version = "1.3.0";

  # Prebuilt release archive, the same one incoai's Homebrew formula installs. It bundles
  # its own Python and the signed Metal engine, so nothing is rebuilt or patched here.
  # To bump: update version, then take the sha256 from
  #   curl -s https://raw.githubusercontent.com/incoai/homebrew-tap/main/Formula/splash.rb | grep -m1 sha256
  src = fetchurl {
    url = "https://github.com/incoai/splash/releases/download/${finalAttrs.version}/splash-${finalAttrs.version}-arm64-macos26.tar.gz";
    sha256 = "9cbf463598367c912ee17eaba27cba4be3d324d688541f7ed5106ed9b2bd691d";
  };

  dontConfigure = true;
  dontBuild = true;
  # Stripping or rewriting the Mach-O binaries would break their code signatures.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin
    cp -R . $out/libexec/

    cat > $out/bin/splash <<EOS
    #!/bin/sh
    export PYTHONDONTWRITEBYTECODE=1
    exec "$out/libexec/python/bin/python3" -u "$out/libexec/install/launcher.py" "\$@"
    EOS
    chmod 0755 $out/bin/splash

    install -Dm644 install/completions/_splash $out/share/zsh/site-functions/_splash
    install -Dm644 install/completions/splash.bash $out/share/bash-completion/completions/splash
    install -Dm644 install/completions/splash.fish $out/share/fish/vendor_completions.d/splash.fish

    runHook postInstall
  '';

  meta = {
    description = "Local inference engine for Apple silicon (macOS 26.4+, M3 or newer)";
    homepage = "https://github.com/incoai/splash";
    license = lib.licenses.asl20;
    mainProgram = "splash";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
