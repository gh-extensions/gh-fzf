{
  description = "gh-fzf development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # The tools that the extension calls, in the PATH of its wrapper
        runtimeInputs = with pkgs; [
          bash
          gh
          fzf
          gum
        ];
      in
      {
        # The extension as gh reads it: a directory named after it with the executable in it. home-manager's
        # programs.gh.extensions links the bin/ of this package as that directory. The script finds its scripts next to
        # itself, so the repository is installed whole in libexec and the wrapper in bin/ only sets the PATH
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          pname = "gh-fzf";
          version = nixpkgs.lib.fileContents ./version.txt;
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/libexec/gh-fzf $out/bin
            cp -r . $out/libexec/gh-fzf
            rm -rf $out/libexec/gh-fzf/{tests,flake.nix,flake.lock,.envrc,.gitignore}
            chmod +x $out/libexec/gh-fzf/gh-fzf

            makeWrapper $out/libexec/gh-fzf/gh-fzf $out/bin/gh-fzf \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeInputs}

            runHook postInstall
          '';

          meta = {
            description = "Interactive fuzzy finder for GitHub CLI";
            homepage = "https://github.com/gh-extensions/gh-fzf";
            license = pkgs.lib.licenses.mit;
            mainProgram = "gh-fzf";
          };
        };

        devShells.default = pkgs.mkShell {
          name = "gh-fzf";
          packages =
            runtimeInputs
            ++ (with pkgs; [
              bats
              shellcheck
            ]);
        };
      }
    );
}
