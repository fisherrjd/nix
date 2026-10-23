let

  machines = {
    nixos = [
      "bifrost"
      "eldo"
      "neverland"
    ];
    darwin = [
      "airbook"
      "gjallar"
    ];

    phone = [
      "jphone"
    ];

  };
  pubkeys = rec {
    atlantis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4ng5nDLLCyQJ0QOHglRBZkBUI/3FV1c2FIAjwQgIK0 jade@Atlantis"; #home desktop
    neverland = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAX2/pWmcbFAPOSs1Vi4/xHRgFT+IDuWBUNGFyM0YlCh jade@neverland"; #home wsl on home desktop
    eldo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbNhnkhqLCDhVYXTQXxuVYkPHnWSBFFmunVSk5ETnZj jade@eldo"; # old pc gone nix server
    bifrost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7/kejaKkGIi6l4i3Nff80DlKQipUOJop4atrdrIN1t jade@bifrost"; #DO droplet
    airbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ8MkkKNzgkqXP0cX0GkvAWET0ko06bDD738ePbQAyUA jade@airbook";
    gjallar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDB35NyHnCwlbLTP+KHILJhv3yjvJgRYNCf1/+fFmfTi jade@sinch";
    iphone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMTS+RbHMA/W8PNpNFoLKVFpSjVmSoF+IYn51SDL9t5W";

    jade = [
      atlantis
      neverland
      eldo
      airbook
      bifrost
      iphone
    ];

    work = [
      gjallar
    ];

    # only the do-builder image still trusts every key; hosts use `logins` below
    all = jade ++ work;
  };
  # who can ssh into each machine, named by the machine the key lives on
  logins = with pubkeys; {
    eldo = [ atlantis airbook ];
    bifrost = [ atlantis eldo airbook ];
    gjallar = [ atlantis ];
    airbook = [ ];
    neverland = [ ];
  };
  # ssh host keys (/etc/ssh/ssh_host_ed25519_key.pub); agenix decrypts with these at boot
  hostkeys = {
    eldo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9Jfl1EHVKlIv1q34kcbt4EZiVr1CF92YgB3Ta2e3zm root@eldo";
    bifrost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3jXIEY4FJ8om7qhoP97K47f/pp9DBEnJOT/bvDdpDI root@bifrost";
  };
in
{
  inherit pubkeys machines hostkeys logins;
}
