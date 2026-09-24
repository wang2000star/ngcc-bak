{
  description = "A Nix-flake-based C/C++ development environment";

  #inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0"; # stable Nixpkgs
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # stable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default =
            pkgs.mkShell.override
              {
                # Override stdenv in order to change compiler:
                # stdenv = pkgs.clangStdenv;
              }
              {
                packages =
                  with pkgs;
                  [
										cmakeWithGui
										gcc
										clang
                    clang-tools
										# scripting
										python314
										sage
										# libs
										openssl
										# formatting
										ruff
										# profiling
										perf
										valgrind
										binutils
										python314Packages.pyserial
										#kdePackages.massif-visualizer
										#kdePackages.kcachegrind
										# for the NGCC benchmarking
										libelf
										cjson
										enscript
										ghostscript
                  ]
                  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [ gdb ];
              };
						shellHook = ''
							export NIX_ENFORCE_NO_NATIVE=0
						'';
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
