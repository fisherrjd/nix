{ lib, config, ... }:
let
  inherit (lib.lists) subtractLists;
  inherit (lib) mkEnableOption;
  inherit (config.conf) work;
in
{
  options.conf.work = {
    enable = mkEnableOption "work";
  };
  config = {
    # nix.linux-builder = {
    #   enable = true;
    #   package = pkgs.darwin.linux-builder-x86_64;
    # };
    system = {
      activationScripts.postUserActivation.text = ''
        # Following line should allow us to avoid a logout/login cycle
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';
      defaults = {
        CustomSystemPreferences = {
          "com.apple.finder" = {
            ShowExternalHardDrivesOnDesktop = true;
            ShowHardDrivesOnDesktop = true;
            ShowMountedServersOnDesktop = true;
            ShowRemovableMediaOnDesktop = true;
            _FXSortFoldersFirst = true;
            # When performing a search, search the current folder by default
            FXDefaultSearchScope = "SCcf";
          };
          "com.apple.desktopservices" = {
            # Avoid creating .DS_Store files on network or USB volumes
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
        };
        NSGlobalDomain = {
          AppleKeyboardUIMode = 3;
          ApplePressAndHoldEnabled = false;
          InitialKeyRepeat = 10;
          KeyRepeat = 1;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
          NSNavPanelExpandedStateForSaveMode = true;
          NSNavPanelExpandedStateForSaveMode2 = true;
          _HIHideMenuBar = false;
        };
        screencapture = { location = "/Desktop"; type = "png"; };
        dock = {
          autohide = false;
          mru-spaces = false;
          orientation = "bottom";
          showhidden = true;
          show-recents = false;
        };
        finder = {
          AppleShowAllExtensions = true;
          QuitMenuItem = true;
          FXEnableExtensionChangeWarning = false;
        };

        trackpad = {
          Clicking = true;
          TrackpadThreeFingerDrag = false;
        };
      };
      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToControl = true;
      };
    };
    programs.bash = {
      enable = true;
      completion.enable = true;
    };
  };
}