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

    # every machine trusts every other machine, so hosts just use `all`
    all = jade ++ work;
  };
in
{
  inherit pubkeys machines;
}
