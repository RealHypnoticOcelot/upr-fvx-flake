{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    upr-fvx-repo = {
      url = "github:upr-fvx/universal-pokemon-randomizer-fvx";
      flake = false;
    };
  };

  outputs = { nixpkgs, upr-fvx-repo, ... } @ inputs:
  let
    packageName = "universal-pokemon-randomizer-fvx";
    forSupportedSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux" # Only supporting one system, because of this BellSoft Liberica thing
    ];
    forSupportedPackages = forSupportedSystems ( # Create a list of nixpkgs objects
      system:
      import nixpkgs {
        inherit system;
      }
    );
  in
  {
    packages = forSupportedSystems (system:
      let
        jmodsArchive = forSupportedPackages.${system}.fetchurl {
          url = "https://download.bell-sw.com/java/25.0.2+12/bellsoft-jdk25.0.2+12-linux-amd64.tar.gz";
          hash = "sha256-jcP0RRsK/+AKbU2gqiMxJAv30UKjU/9SlnNQH4vQnEo=";
        };
      in
      {
      default = forSupportedPackages.${system}.stdenv.mkDerivation (finalAttrs: {
        pname = packageName;
        version = "1.6.3";
        src = upr-fvx-repo;

        desktopItems = [(
          forSupportedPackages.${system}.makeDesktopItem {
            name = packageName;
            exec = packageName;
            icon = "${upr-fvx-repo}/docs/src/assets/images/gen5_pokeball.png";
            desktopName = "Universal Pokemon Randomizer FVX";
            genericName = "Pokémon game randomizer for generations 1-7";
          }
        )];

        nativeBuildInputs = with forSupportedPackages.${system}.pkgs; [
          makeWrapper
          gradle_9
          copyDesktopItems
        ];

        mitmCache = forSupportedPackages.${system}.gradle_9.fetchDeps {
          pkg = finalAttrs.finalPackage; 
          data = ./deps.json; # To generate a new ./deps.json, run $(nix build .#default.mitmCache.updateScript --print-out-paths)
        };

        patches = [
          ./0001-Provide-BellSoft-Liberica.patch
          ./0002-Change-file-picker-starting-directory.patch
        ];

        # this is required for using mitm-cache on Darwin
        __darwinAllowLocalNetworking = true;

        gradleBuildTask = "random:moveIntoReleaseDirLinuxx86";

        gradleFlags = [
          "-PjmodsArchive=${jmodsArchive}"
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          makeWrapper ${nixpkgs.lib.getExe forSupportedPackages.${system}.jdk25} $out/bin/${packageName} \
            --add-flags "-Xmx4608M -jar $out/bin/UPR-FVX.jar please-use-the-launcher"
          cp random/build/target/Linux_x86/UPR-FVX.jar $out/bin
          cp -R random/build/target/Linux_x86/data $out/bin

          runHook postInstall
        '';
        });
      }
    );
  };
}
# Run `nix develop` to enter the shell, and run `exit` to leave the shell