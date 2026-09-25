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
      ver = "2.0.28";
      archives = {
        aarch64-darwin = { target = "darwin-arm64"; sha256 = "b7f6cece79523ff1bb66a2754073f607683015982028111eee2149114dbdb847"; };
        x86_64-darwin  = { target = "darwin-x64";   sha256 = "f355d02c9b858c669988dbd4c64af5798b5c0397df518d36005e6ebc87e1684f"; };
        aarch64-linux  = { target = "linux-arm64";  sha256 = "c45ace45bee868d44115cb8cddbe501b6a49a4b7f7a1019c50c3973d8c500fe0"; };
        x86_64-linux   = { target = "linux-x64";    sha256 = "22bb6d5f6bce8ae2c5b340371fedddcbd90edc07a48b6e2b351a944c4558a3eb"; };
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
