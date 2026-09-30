{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "buzz-relay";
  version = "0.2.1-unstable-2026-09-30";

  # To bump: set rev to a newer block/buzz commit, then replace both hashes with
  # lib.fakeHash and rebuild; nix prints the correct values.
  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    rev = "2664d14316790a57ea44b3f97c57440b70e43436";
    hash = "sha256-28hY8dkwutFP2HrWkOQF3P1znfYBx+tPfOccnP14tm8=";
  };

  cargoHash = "sha256-A/lpudjM3ZahSNiWHxW8UKFlBhdBuAEQL87c8Q+C7Q4=";

  cargoBuildFlags = [ "-p" "buzz-relay" "--bin" "buzz-relay" ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  # The workspace test suite needs Postgres and Redis.
  doCheck = false;

  meta = {
    description = "Buzz WebSocket relay server (NIP-29 communities)";
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    mainProgram = "buzz-relay";
  };
})
