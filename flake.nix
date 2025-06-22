{
  description = "OxCaml dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    oxcaml = {
      url = "github:oxcaml/oxcaml";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, oxcaml }: 
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            oxcaml = prev.stdenv.mkDerivation {
              pname = "oxcaml";
              src = oxcaml;
              inherit (prev.ocaml) ocaml;  # Use OCaml compiler
              buildInputs = [ prev.ocaml ]; 
              installPhase = ''
                mkdir -p $out/bin
                cp _build/default/bin/ocamlc.opt $out/bin/ocamlc
                cp _build/default/bin/ocamlopt.opt $out/bin/ocamlopt
              '';
            };
          })
        ];
      };
    in {
      devShells.${builtins.currentSystem} = pkgs.mkShell {
        buildInputs = [
          pkgs.oxcaml
          pkgs.ocamlPackages.dune
          pkgs.ocamlPackages.merlin
          pkgs.ocamlPackages.ocaml-lsp-server
        ];
        shellHook = ''
          echo "Use ocamlc/ocamlopt from OxCaml"
        '';
      };
    };
}

