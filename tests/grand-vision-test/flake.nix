{
  description = "Minimal example of dumping rnix AST using rnix-parser.";

  inputs = {
    nixpkgs.url = "github:meta-introspector/nixpkgs?ref=feature/CRQ-016-nixify";
    flake-utils.url = "github:meta-introspector/flake-utils?ref=feature/CRQ-016-nixify";
    rnix-parser.url = "github:meta-introspector/rnix-parser?ref=feature/CRQ-016-nixify-workflow"; # Reference the rnix-parser flake from GitHub
  };

  outputs = { self, nixpkgs, flake-utils, rnix-parser }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        dumpAstExecutable = "${rnix-parser.packages.${system}.rnix-parser}/bin/dump-ast";
        nixFileToAnalyze = ../../flake.nix; # Analyze rnix-parser's own flake.nix
      in
      rec {
        packages.dumpRnixAst = pkgs.runCommand "rnix-ast-dump"
          {
            nativeBuildInputs = [ pkgs.bash ];
            buildInputs = [ rnix-parser.packages.${system}.rnix-parser ]; # Ensure dump-ast is in PATH
          } ''
          mkdir -p $out
          ${dumpAstExecutable} "${nixFileToAnalyze}" > "$out/rnix-flake-ast.json"
        '';
        defaultPackage = packages.dumpRnixAst;
      }
    );
}