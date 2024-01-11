{
  description = "purescript-bytearrays";

  # Allow IFD in `nix flake check`.
  nixConfig.allow-import-from-derivation = "true";

  nixConfig = {
    extra-substituters = [ "https://plutonomicon.cachix.org" ];
    extra-trusted-public-keys = [ "plutonomicon.cachix.org-1:evUxtNULjCjOipxwAnYhNFeF/lyYU1FeNGaVAnm+QQw=" ];
    bash-prompt = "\\[\\e[0m\\][\\[\\e[0;2m\\]nix-develop \\[\\e[0;1m\\]ps-bytearrays@\\[\\033[33m\\]$(git rev-parse --abbrev-ref HEAD) \\[\\e[0;32m\\]\\w\\[\\e[0m\\]]\\[\\e[0m\\]$ \\[\\e[0m\\]";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = github:hercules-ci/flake-parts;
    hercules-ci-effects.url = github:hercules-ci/hercules-ci-effects;
    easy-purescript-nix = {
      url = "github:justinwoo/easy-purescript-nix";
      flake = false;
    };
  };

  outputs = inputs @ { self, flake-parts, hercules-ci-effects, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ ... }: {
      imports = [
        # Hercules CI effects module used to deploy to GitHub Pages
        hercules-ci-effects.flakeModule
      ];

      # Systems supported by this flake
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { self', pkgs, system, ... }:
        let
          easy-ps = (import inputs.easy-purescript-nix { pkgs = pkgs; });
        in
          {

            devShells = {
              default = pkgs.mkShell {
                buildInputs = with pkgs; [
                  nixpkgs-fmt
                  easy-ps.purs
                  easy-ps.purs-tidy
                  easy-ps.spago
                  easy-ps.pscid
                  easy-ps.psa
                  easy-ps.spago2nix
                  nodePackages.eslint
                  nodePackages.prettier
                  esbuild
                  python3 # for http.server to serve the test
                  fd
                  git
                  nodejs-18_x
                ];
              };
            };

            # Example flake checks. Run with `nix flake check --keep-going`
            checks = {
              formatting-check = pkgs.runCommand "formatting-check"
                {
                  nativeBuildInputs = with pkgs; [
                    easy-ps.purs-tidy
                    nixpkgs-fmt
                    nodePackages.prettier
                    nodePackages.eslint
                    fd
                  ];
                }
                ''
                cd ${self}
                purs-tidy check './src/**/*.purs' './test/**/*.purs'
                nixpkgs-fmt --check "$(fd --no-ignore-parent -enix --exclude='spago*')"
                prettier --log-level warn -c $(fd --no-ignore-parent -ejs -ecjs)
                eslint --quiet $(fd --no-ignore-parent -ejs -ecjs) --parser-options 'sourceType: module'
                touch $out
              '';
            };
          };

      # On CI, build only on available systems, to avoid errors about systems without agents.
      # Please use aarch64-linux and x86_64-darwin sparingly as they run on smaller hardware.
      herculesCI.ciSystems = [ "x86_64-linux" ];

      # Schedule task to run `nix flake update`, run CI, and open a PR with changes
      hercules-ci.flake-update = {
        enable = true;
        when = {
          dayOfWeek = "Sun";
          hour = 12;
          minute = 45;
        };
      };
    });
}
