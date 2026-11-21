# Universal Pokemon Randomizer FVX Nix Flake

This flake only supports `x86-64_linux` machines!

## Usage:

flake.nix:
```nix
{
  inputs = {
    upr-fvx = {
      url = "github:RealHypnoticOcelot/upr-fvx-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  }
}
```

configuration.nix:
```nix
{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  upr-fvxPkg = inputs.upr-fvx.packages.${system}.default;
in {
  environment.systemPackages = [
    upr-fvxPkg
  ];
}
```

## Building

To create a production version of your app:

```sh
nix build
```
You can preview the production build with `nix run`.