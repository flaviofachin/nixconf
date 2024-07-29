{
  pkgs,
  inputs,
  config,
  ...
}: let
   current-user =config.users.current-user;
in
  {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops.defaultSopsFile = ./../../hosts/secrets.yaml;
    sops.defaultSopsFormat = "yaml";
    # sops.age.sshKeyPaths = [ "/home/${current-user}/.ssh/testkey" ];
    sops.age.generateKey = true;
    sops.age.keyFile = "/home/${current-user}/.config/sops/age/keys.txt";

    sops.secrets.example-key = {
      owner = config.users.users.${current-user};
    };
    sops.secrets."myservice/my_subdir/my_secret" = {
      # owner = current-user;
      owner = "sometestservice";
    };

    systemd.services."sometestservice" = {
      script = ''
        echo "
        Hey bro! I'm a service, and imma send this secure password:
        $(cat ${config.sops.secrets."myservice/my_subdir/my_secret".path})
        located in:
        ${config.sops.secrets."myservice/my_subdir/my_secret".path}
        to database and hack the mainframe 😎👍
        " > /var/lib/sometestservice/testfile
      '';
      serviceConfig = {
        User = "sometestservice";
        WorkingDirectory = "/var/lib/sometestservice";
      };
    };

    users.users.sometestservice = {
      home = "/var/lib/sometestservice";
      createHome = true;
      isSystemUser = true;
      group = "sometestservice";
    };
    users.groups.sometestservice = {};
  };
}
