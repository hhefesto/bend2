# Nix flake for Bend, written by release.ts (in the bend-lang.com repo,
# from release/flake.nix.in) with the version and the sha256 of each
# release archive filled in: do not bump it by hand. The package fetches
# the host's archive from GitHub Releases, the same one install.sh and
# the Homebrew formula install, lands it whole in libexec/bend (bin/bend
# beside bend2/ and guide/, the layout the executable expects) and puts
# a wrapper at bin/bend that adds clang to PATH on Linux (bend -o needs
# clang 14+) and names Apple's clang on macOS. On Linux the Bun
# executable is patched to find the store's glibc. Use:
# `nix profile install github:bendlang/bend`, `nix run github:bendlang/bend`,
# or `inputs.bend.url = "github:bendlang/bend"` and
# `inputs.bend.packages.${system}.default` in a flake.
#
# The ft-kernels fork (github:hhefesto/bend2) adds one package and renames
# one: `default` is THIS source tree run by Bun (bend2/main.ts, with the
# fork's bulk GPU ops and file effects; calling main.ts directly also skips
# the release launcher's telemetry and self-update), and upstream's release
# archive is `release`. Everything else is upstream's, as release.ts wrote
# it, so a rebase conflicts here only on the version and hashes.
{
  description = "Bend: C speed, CUDA parallelism, Lean proofs, Python syntax";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      ver = "2.0.37";
      archives = {
        aarch64-darwin = { target = "darwin-arm64"; sha256 = "846d25ccf0c12d5d1e5e648c0b3ba4c8397fdb852812ac00ef8135998f8e194b"; };
        x86_64-darwin  = { target = "darwin-x64";   sha256 = "93eea3f54b7b91f28ea15a1b9f2d825afa58c1fcd417c11024a62f8c3506b813"; };
        aarch64-linux  = { target = "linux-arm64";  sha256 = "b65d452e5c68a4c486e353220d4298ba5d76f535db47109a7d76ffdf72efafb1"; };
        x86_64-linux   = { target = "linux-x64";    sha256 = "84c32465a39bc9ac315eade23f470cb8db03153dc860f89564fcfec153c3e445"; };
      };
      each = f: nixpkgs.lib.mapAttrs (system: archive:
        f (import nixpkgs { inherit system; }) archive) archives;
      # the files bend2/main.ts reads at run time: the compiler and runtime,
      # and the guide it prints
      source = nixpkgs.lib.fileset.toSource {
        root = ./.;
        fileset = nixpkgs.lib.fileset.unions [ ./bend2 ./guide ./LICENSE ];
      };
    in {
      packages = each (pkgs: archive: {
        default = pkgs.writeShellApplication {
          name = "bend";
          runtimeInputs = [ pkgs.bun ]
            ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.clang;
          text = ''
            export BEND_NO_TELEMETRY=1
            ${if pkgs.stdenv.hostPlatform.isLinux then "unset CC"
              else ": \"''${CC:=/usr/bin/clang}\"; export CC"}
            exec bun ${source}/bend2/main.ts "$@"
          '';
          meta = {
            description = "Bend from source (the ft-kernels fork)";
            mainProgram = "bend";
          };
        };
        release = pkgs.stdenv.mkDerivation {
          pname = "bend";
          version = ver;
          src = pkgs.fetchurl {
            url = "https://github.com/bendlang/bend/releases/download/v${ver}/"
              + "bend-${ver}-${archive.target}.tar.gz";
            inherit (archive) sha256;
          };
          nativeBuildInputs = [ pkgs.makeWrapper ]
            ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
          dontBuild = true;
          dontStrip = true;
          installPhase = ''
            mkdir -p $out/libexec/bend $out/bin
            cp -r . $out/libexec/bend
            makeWrapper $out/libexec/bend/bin/bend $out/bin/bend \
              ${if pkgs.stdenv.hostPlatform.isLinux
                then ''--prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.clang ]}"''
                else "--set-default CC /usr/bin/clang"}
          '';
          meta = {
            description = "Bend: C speed, CUDA parallelism, Lean proofs, Python syntax";
            homepage = "https://bend-lang.com";
            license = pkgs.lib.licenses.asl20;
            mainProgram = "bend";
          };
        };
      });
      apps = each (pkgs: archive: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.system}.default}/bin/bend";
        };
      });
    };
}
