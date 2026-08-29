{ lib
, runCommand
}:

# A single hand-written page rather than a generator. wisp's documentation is currently one
# page long, and mdBook or similar would add a build dependency plus a lot of chrome to serve
# less content than it ships. Swap this for a generator when there is enough to warrant nav.
#
# The source lives here rather than in the wisp repo on purpose: bifrost builds from this repo,
# and the wisp flake input is a path on Jade's laptop (git+file://), which a server config
# should not depend on. Move it into the wisp repo once that input points at a real remote.
runCommand "wisp-docs"
{
  meta = {
    description = "Static documentation site for wisp, served at wisp.jade.rip";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ''
  mkdir -p $out
  cp ${./index.html} $out/index.html
''
