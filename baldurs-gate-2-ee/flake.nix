rec {
  description = "Baldur's Gate II: Enhanced Edition, the classic BioWare RPG";

  inputs.nixpkgs.url = "nixpkgs/nixos-20.03";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux = {

      baldurs-gate-2-ee =
        with import nixpkgs { config.permittedInsecurePackages = [ "openssl-1.0.2u" ]; system = "x86_64-linux"; };

        let
          version = "2.5.21851";

          url = "https://www.gog.com/game/baldurs_gate_2_enhanced_edition";

          /* Put the game data in a fixed-output derivation so we don't need
             to rebuild it when the wrapper script changes. */
          data =
            runCommand "baldurs-gate-2-ee-${version}-data"
              {
                outputHashMode = "recursive";
                outputHash = "sha256-JoTAqm+sqUsl0rSCYkO/Eq1/Fv2XqRoA4GXHWaoKiE8=";

                buildInputs = [ unzip ];

                src = requireFile {
                  name = "baldur_s_gate_2_enhanced_edition_en_${builtins.replaceStrings ["."] ["_"] version}.sh";
                  sha256 = "333af033caabad345fea862bd12839856bbed192eb6ae6d6b45ac1f5035b9950";
                  inherit url;
                };
              }
              ''
                # "|| true" is needed to ignore the warning about the
                # extraneous data at the start.
                unzip "$src" -d $out || true
              '';

          libPath = lib.makeLibraryPath
            [ openal
              gcc.cc
              openssl_1_0_2
              expat
              xorg.libX11
            ];

        in stdenv.mkDerivation rec {
          name = "baldurs-gate-2-ee-${version}";

          buildCommand =
            ''
              lib=$out/lib/baldurs-gate-2-ee

              mkdir -p $out/bin $lib

              ln -s ${json_c}/lib/libjson-c.so.? $lib/libjson.so.0

              cat > $out/bin/BaldursGateII <<EOF
              cd ${data}/data/noarch/game
              LD_LIBRARY_PATH=$lib:${libPath}:\$LD_LIBRARY_PATH:${libGL}/lib exec ${glibc}/lib/ld-linux-x86-64.so.2 ./BaldursGateII64
              EOF

              chmod +x $out/bin/BaldursGateII
            '';

          meta = {
            inherit description;
            homepage = url;
            #license = lib.licenses.unfree;
          };
        };

    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.baldurs-gate-2-ee;

    defaultApp.x86_64-linux = {
      type = "app";
      program = "${self.packages.x86_64-linux.baldurs-gate-2-ee}/bin/BaldursGateII";
    };

  };
}
