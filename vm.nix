{
  pkgs,
  config,
  lib,
  ...
}: {
  system.stateVersion = "24.05";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # openssh: passwordless auth enabled for root user by default
  services.openssh.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    settings = {
      shared_preload_libraries = [ "auto_explain" ];
      log_connections = true;
      log_statement = "all";
      logging_collector = true;
      log_disconnections = true;
      log_destination = lib.mkForce "syslog";
      # Search more on https://search.nixos.org/options
    };
  };

  documentation.enable = true;
  
  # ! This is creating a script at /etc/current-system-packages
  environment.etc."current-system-packages".text = let
    packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
    sortedUnique = builtins.sort builtins.lessThan (pkgs.lib.lists.unique packages);
    formatted = builtins.concatStringsSep "\n" sortedUnique;
  in
    formatted;

  environment.systemPackages = with pkgs; [nix-index pgbadger];

  nixos-shell.mounts = {
    mountHome = false;
    mountNixProfile = false;
    cache = "none"; 
    extraMounts = {
      "/playground" = /home/krissou/Documents/playground/profilingAce;
    };
  };
  virtualisation = {
    diskSize = 3 * 1024; # GB 
    forwardPorts = [
      {from = "host"; host.port = 2222; guest.port = 22;}
    ];
  };
  nix = {
    # Avoid having to download a nix-channel every time the VM is reset
    nixPath = [
      "nixpkgs=${pkgs.path}"
    ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
