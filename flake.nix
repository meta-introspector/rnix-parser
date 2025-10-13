{
  description = "Rust-based parser for nix files";

  inputs = {
    utils.url = "github:meta-introspector/flake-utils?ref=feature/CRQ-016-nixify";
    nixpkgs.url = "github:meta-introspector/nixpkgs?ref=feature/CRQ-016-nixify";
    import-cargo.url = "github:meta-introspector/import-cargo?ref=feature/CRQ-016-nixify";
  };

  # first comment
  # second comment
  outputs = { self, nixpkgs, utils, import-cargo }:
    {
      overlay = final: prev:
        let
          target = final.rust.toRustTarget final.stdenv.hostPlatform;
          flags = "--release --offline --target ${target}";
          inherit (import-cargo.builders) importCargo;
        in
        {
          rnix-parser = final.stdenv.mkDerivation {
            pname = "rnix-parser";
            version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
            src = final.lib.cleanSource ./.;
            nativeBuildInputs = with final; [
              rustc
              cargo
              (importCargo { lockFile = ./Cargo.lock; inherit (final) pkgs; }).cargoHome
            ];

            outputs = [ "out" "doc" ];
            doCheck = true;

            buildPhase = ''
              cargo build ${flags}
              cargo build --release --example dump-ast --target ${target}
              cargo doc ${flags}
            '';

            checkPhase = ''
              cargo test ${flags}
              cargo bench
            '';

            installPhase = ''
              mkdir -p $out/lib
              mkdir -p $out/bin
              mkdir -p $doc/share/doc/rnix

              cp -r ./target/${target}/doc $doc/share/doc/rnix
              cp ./target/${target}/release/librnix.rlib $out/lib/
              cp ./target/${target}/release/examples/dump-ast $out/bin/
            '';
          };
        };
    }
    // utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
      in
      rec {
        # `nix develop`
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ rustfmt rustc cargo clippy ];
        };

        packages.rnix-parser = pkgs.rnix-parser;
        defaultPackage = packages.rnix-parser;
      }
    );
}
