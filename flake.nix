{
  description = "Flake to build OxCaml from source, with a dev shell including Dune 3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Optionally pin a specific revision to ensure dune_3 is available
    # nixpkgs.url = "github:NixOS/nixpkgs/your-commit-hash";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";  # or "aarch64-linux"
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
      ocamlPkgs = pkgs.ocamlPackages;
    in {
      packages.${system}.oxcaml = pkgs.stdenv.mkDerivation {
        pname = "oxcaml";
        version = "main";

        src = pkgs.fetchFromGitHub {
          owner = "oxcaml";
          repo = "oxcaml";
          rev = "main";
          sha256 = lib.fakeSha256;
        };

        nativeBuildInputs = [
          pkgs.autoconf
          pkgs.automake
          pkgs.libtool
          pkgs.m4
          pkgs.pkg-config
        ];

        buildInputs = [
          ocamlPkgs.ocaml
          # Use Dune 3 for any parts that invoke dune
          (builtins.tryEval ''${toString ocamlPkgs.dune_3}'' // { success = true; value = ocamlPkgs.dune; })
          # If dune_3 attribute exists, prefer that; else fallback to ocamlPkgs.dune
          ocamlPkgs.menhir
        ];

        configurePhase = ''
          autoreconf -ivf
          ./configure \
            --prefix=$out \
            --enable-runtime5
        '';

        buildPhase = ''
          make world.opt
        '';
        installPhase = ''
          make install
        '';
      };

      devShells.${system}.default = pkgs.mkShell {
        # Development dependencies: OCaml compiler, Dune 3, and build tools
        buildInputs = [
          ocamlPkgs.ocaml
          # Prefer dune_3 if available; otherwise use dune
          (if builtins.hasAttr "dune_3" ocamlPkgs then ocamlPkgs.dune_3 else ocamlPkgs.dune)
          ocamlPkgs.findlib
          ocamlPkgs.merlin        # for editor integration, if desired
          pkgs.pkg-config
          pkgs.autoconf
          pkgs.automake
          pkgs.libtool
          pkgs.m4
        ];

        # Optional: set environment variables or hints
        shellHook = ''
          echo "OCaml $(ocamlc -version) available, Dune version: $(dune --version)"
          echo "To build OxCaml: nix build .#oxcaml"
        '';
      };

      # Expose default package
      defaultPackage = self.packages.${system}.oxcaml;
      defaultDevShell = self.devShells.${system}.default;
    };
}
