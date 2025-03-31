let
  # TODO Abstract keys properly from common
  # common = import ../common.nix;
  neverland = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAX2/pWmcbFAPOSs1Vi4/xHRgFT+IDuWBUNGFyM0YlCh jade@neverland"; #home wsl on home desktop
  eldo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbNhnkhqLCDhVYXTQXxuVYkPHnWSBFFmunVSk5ETnZj jade@eldo"; # old pc gone nix server
  airbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaWm9is28MRcO96v72pHvWQuZ+NiM0t3iFmC4mq3jsJ jade@airbook"; # m1 macbook air
  dev = [ neverland eldo airbook ];

in
{
  "litellm.age".publicKeys = dev;
  "openwebui.age".publicKeys = dev;
}
