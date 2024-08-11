{config, pkgs, lib, ...}:
{
  # enable quirks (e.g. set $XDG_DATA_DIRS environment variable) for non NixOS operating systems 
  targets.genericLinux.enable = true;

  # enable proprietary software
  nixpkgs.config.allowUnfree = true;

  # install software
  home.packages = with pkgs; [
    nano
  ];

  home.username = "coder";
  home.homeDirectory = "/home/coder";
  home.stateVersion = "@version@";
}
