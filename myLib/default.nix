{inputs}: let
  myLib = (import ./default.nix) {inherit inputs;};
  outputs = inputs.self.outputs;
in rec {
  # ================================================================ #
  # =                            My Lib                            = #
  # ================================================================ #

  # ======================= Package Helpers ======================== #

  pkgsFor = sys: inputs.nixpkgs.legacyPackages.${sys};

  # ========================== Buildables ========================== #
  mkCommons = {config}:
    import ./modules/commons {config; nix-users;};

  mkSystem = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs outputs myLib;
      };
      modules = [
        config
        outputs.nixosModules.default
      ];
    };

  mkHome = sys: config:
    mkCommons {config;} // inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor sys;
      extraSpecialArgs = {
        inherit inputs myLib outputs;
      };
      modules = [
        config
        outputs.homeManagerModules.default
      ];
    };

  # =========================== Helpers ============================ #

  filesIn = dir: (map (fname: dir + "/${fname}")
    (builtins.attrNames (builtins.readDir dir)));

  dirsIn = dir:
    inputs.nixpkgs.lib.filterAttrs (name: value: value == "directory")
    (builtins.readDir dir);

  fileNameOf = path: (builtins.head (builtins.split "\\." (baseNameOf path)));

  # ========================== Extenders =========================== #

  # Evaluates nixos/home-manager module and extends it's options / config
  extendModule = {path, ...} @ args: {pkgs, ...} @ margs: let
    eval =
      if (builtins.isString path) || (builtins.isPath path)
      then import path margs
      else path margs;
    evalNoImports = builtins.removeAttrs eval ["imports" "options"];

    extra =
      if (builtins.hasAttr "extraOptions" args) || (builtins.hasAttr "extraConfig" args)
      then [
        ({...}: {
          options = args.extraOptions or {};
          config = args.extraConfig or {};
        })
      ]
      else [];
  in {
    imports =
      (eval.imports or [])
      ++ extra;

    options =
      if builtins.hasAttr "optionsExtension" args
      then (args.optionsExtension (eval.options or {}))
      else (eval.options or {});

    config =
      if builtins.hasAttr "configExtension" args
      then (args.configExtension (eval.config or evalNoImports))
      else (eval.config or evalNoImports);
  };

  # Applies extendModules to all modules
  # modules can be defined in the same way
  # as regular imports, or taken from "filesIn"
  extendModules = extension: modules:
    map
    (f: let
      name = fileNameOf f;
    in (extendModule ((extension name) // {path = f;})))
    modules;
magicDirs = dirs: 
    genAttrs dirs
    (dir:
      myLib.extendModules
        (name: {
          extraOptions = {
            myNixOS.${dir}.enable = lib.mkEnableOption "enable my ${dir} configuration";
          };

          configExtension = config: (lib.mkIf cfg.${name}.enable config);
      })
    (myLib.filesIn ./${dir});
);

#The follow create the application without polluting permanently the store with all de dependency
mkApp = name: dependOn:    # Args es:  bakup [restic sops nettools]
      let
        newApp = name: script: {
          type = "app";
          program = toString (pkgs.writeShellScript "${name}.sh" script);
        };
      in {
        ${name} = newApp name ''
          PATH=${
              with pkgs; lib.makeBinPath dependOn
          }
          ${pkgs.lib.fileContents ./scripts/${name}.sh}
        '';

# The follow create the derivation con all the dependecy in the /nix/store
mkApp2 = name: dependOn:
     let
        my-script = pkgs.lib.fileContents ./script/${name}.sh
        my-buildInputs = with pkgs; [ cowsay ddate ];
      in pkgs.symlinkJoin {
        name = my-name;
        paths = [ my-script ] ++ my-buildInputs;
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/${my-name} --prefix PATH : $out/bin";
      };

  # ============================ Shell ============================= #
  forAllSystems = pkgs:
    inputs.nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ]
    (system: pkgs inputs.nixpkgs.legacyPackages.${system});
}
