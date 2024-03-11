{
  description = "A Ruby dev environment for Human Essentials Development";

  nixConfig = {
    extra-substituters = "https://nixpkgs-ruby.cachix.org";
    extra-trusted-public-keys =
      "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM=";
  };

  inputs = {
    nixpkgs.url = "nixpkgs";
    ruby-nix = {
      url = "github:inscapist/ruby-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bundix = {
      url = "github:inscapist/bundix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fu.url = "github:numtide/flake-utils";
    bob-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, fu, ruby-nix, bundix, bob-ruby }:
    with fu.lib;
    eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ bob-ruby.overlays.default ];
        };
        rubyNix = ruby-nix.lib pkgs;

        gemset =
          if builtins.pathExists ./gemset.nix then import ./gemset.nix else { };
        
        gemConfig = {
          mini_racer = attrs: {
            buildInputs = [ pkgs.icu ];
            dontBuild = false;
            NIX_LDFLAGS = "-licui18n";
          };
          libv8-node =
            let
              noopScript = pkgs.writeShellScript "noop" "exit 0";
              linkFiles = pkgs.writeShellScript "link-files" ''
                cd ../..

                mkdir -p vendor/v8/${system}/libv8/obj/
                ln -s "${pkgs.nodejs_18.libv8}/lib/libv8.a" "vendor/v8/${system}/libv8/obj/libv8_monolith.a"

                ln -s ${pkgs.nodejs_18.libv8}/include vendor/v8/include

                mkdir -p ext/libv8-node
                echo '--- !ruby/object:Libv8::Node::Location::Vendor {}' >ext/libv8-node/.location.yml
              '';
            in
            attrs: {
              dontBuild = false;
              postPatch = ''
                cp ${noopScript} libexec/build-libv8
                cp ${noopScript} libexec/build-monolith
                cp ${noopScript} libexec/download-node
                cp ${noopScript} libexec/extract-node
                cp ${linkFiles} libexec/inject-libv8
              '';
            };
        };

        updateDeps = pkgs.writeScriptBin "update-deps" (builtins.readFile
          (pkgs.substituteAll {
            src = ./scripts/nix-update.sh;
            bundix = "${pkgs.bundix}/bin/bundix";
          }));
        setupDb = pkgs.writeScriptBin "setup-db" (builtins.readFile
          (pkgs.substituteAll {
            src = ./scripts/nix-db-setup.sh;
          }));

        # See available versions here: https://github.com/bobvanderlinden/nixpkgs-ruby/blob/master/ruby/versions.json
        ruby = pkgs."ruby-3.2.2";

        bundixcli = bundix.packages.${system}.default;
      in rec {
        inherit (rubyNix {
          inherit gemset ruby;
          name = "ruby-env-human-essentials";
          gemConfig = pkgs.defaultGemConfig // gemConfig;
        })
          env;

        devShells = rec {
          default = dev;
          dev = pkgs.mkShell {
            BUNDLE_FORCE_RUBY_PLATFORM = "true";
            shellHook = ''
              export PS1='\n\[\033[1;34m\][💎:\w]\$\[\033[0m\] '

              # Setup postgres database
              export PGHOST=$HOME/postgres
              export PG_HOST=$PGHOST
              export PGDATA=$PGHOST/data
              export PGDATABASE=postgres
              export PGLOG=$PGHOST/postgres.log

              mkdir -p $PGHOST

              if [ ! -d $PGDATA ]; then
                initdb --auth=trust --no-locale --encoding=UTF8
                pg_ctl start -l $PGLOG -o "--unix_socket_directories='$PGHOST'"
                setup-db
              fi

              if ! pg_ctl status
              then
                pg_ctl start -l $PGLOG -o "--unix_socket_directories='$PGHOST'"
              fi

              trap 'pg_ctl stop -D "$PGDATA" -s -m fast' EXIT
            '';

            buildInputs = [
              env
              updateDeps
              setupDb
              bundixcli
              pkgs.bundix
              pkgs.bundler-audit
              pkgs.direnv
              pkgs.git
              pkgs.gnumake
              pkgs.libpcap
              pkgs.libpqxx
              pkgs.libxml2
              pkgs.libxslt
              pkgs.pkg-config
              pkgs.postgresql
            ];
          };
        };
      });
}
