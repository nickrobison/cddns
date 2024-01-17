{
  description = "CDDNS project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    opam-nix = {
     url = "github:tweag/opam-nix";
     inputs.nixpkgs.follows = "nixpkgs";
     inputs.flake-utils.follows = "flake-utils";
    };
    ocamllsp = {
      url = "git+https://github.com/ocaml/ocaml-lsp?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {self, nixpkgs, flake-utils, ocamllsp, opam-nix}:
    let package = "cddns";
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        devPackagesQuery = {
          merlin = "*";
          ocaml-lsp-server = "*";
          ocamlformat = "*";
        };
        query = devPackagesQuery // {
          ocaml-base-compiler = "*";
        };
        on = opam-nix.lib.${system};
        scope = on.buildOpamProject' {} ./. query;
        overlay = final: prev: {
          ${package} = prev.${package}.overrideAttrs (_: {
            # Prevent the ocaml dependencies from leaking into dependent environments
            doNixSupport = false;
          });
        };
        scope' = scope.overrideScope' overlay;
        # The main package containing the executable
        main = scope'.${package};
        # Packages from devPackagesQuery
        devPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');
        in {
          packages.default = main;
          devShells.default = pkgs.mkShell {
            inputsFrom = [main];
            buildInputs = devPackages ++ [
            ];
          };
        });
}
