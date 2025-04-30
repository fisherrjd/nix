let
  pubkeys = rec {
    atlantis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4ng5nDLLCyQJ0QOHglRBZkBUI/3FV1c2FIAjwQgIK0 jade@Atlantis"; #home desktop
    neverland = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAX2/pWmcbFAPOSs1Vi4/xHRgFT+IDuWBUNGFyM0YlCh jade@neverland"; #home wsl on home desktop
    eldo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbNhnkhqLCDhVYXTQXxuVYkPHnWSBFFmunVSk5ETnZj jade@eldo"; # old pc gone nix server
    airbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaWm9is28MRcO96v72pHvWQuZ+NiM0t3iFmC4mq3jsJ jade@airbook"; # m1 macbook air
    workbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMR5a3uP1lZndQ8BZhirgYwHwbZNdzeoLeAwdOnslZf jade@work"; #m1pro work CHARTER
    bifrost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKz+MKsAIJwcp/KOmafEWebxPiZ+GrqvGrfYKi6VSljR jade@bifrost"; #DO droplet

    dev = [
      neverland
      eldo
      airbook
      bifrost
    ];

    work = [
      workbook
    ];

    all = dev ++ work;
  };
in
{
  inherit pubkeys;
}
