#!/usr/bin/env bash
#                 ___  ___      _      __           _ _      
#  _ __  __ _ __ / _ \/ __|  __| |___ / _|__ _ _  _| | |_ ___
# | '  \/ _` / _| (_) \__ \ / _` / -_)  _/ _` | || | |  _(_-<
# |_|_|_\__,_\__|\___/|___/ \__,_\___|_| \__,_|\_,_|_|\__/__/
# Created by Ryan Summer     For macOS 12-26     Version 1.4
#
# Updated 11/04/2025
#
# Note:
#   To see all available options not used here or to see what works or doesn't work
#   on certain macOS versions, please check out the MacOS Preferences menu option
#   in my free tool 'OneCommand (Lite)' here: https://shop.ryansummer.com/p/onecommand/

# === COLOR DEFINITIONS ===
NC=$'\033[0m'
BO=$'\033[1m'
GY=$'\033[2m'
RE=$'\033[1;31m'
GR=$'\033[1;32m'
YE=$'\033[1;33m'
BL=$'\033[1;34m'
MA=$'\033[1;35m'
CY=$'\033[1;36m'

# navigation codes
NAV_BACK=0
NAV_CONT=1
NAV_QUIT=2

# === CONFIGURATION FLAGS ===
MACOS_VERSION=""    # "tahoe", "sequoia", "sonoma", "ventura", "monterey"
ARCH_TYPE=""        # "arm64" or "intel"
MODEL_TYPE=""       # "desktop" or "laptop"
VIRTUALIZATION=""   # "physical" or "vm"

# Detect macOS Version
product_version=$(sw_vers -productVersion)
os_vers=( ${product_version//./ } )
MACOS_MAJOR="${os_vers[0]}"
MACOS_MINOR="${os_vers[1]}"
MACOS_PATCH="${os_vers[2]}"
# os_vers_build=$(sw_vers -buildVersion)

# Get macOS Version Name
case "$MACOS_MAJOR" in
    26)
        MACOS_NAME="Tahoe"
        ;;
    15)
        MACOS_NAME="Sequoia"
        ;;
    14)
        MACOS_NAME="Sonoma"
        ;;
    13)
        MACOS_NAME="Ventura"
        ;;
    12)
        MACOS_NAME="Monterey"
        ;;
    11)
        MACOS_NAME="Big Sur"
        ;;
    10)
        # Determine exact 10.x version
        if   [[ "$MACOS_MINOR" -ge 15 ]]; then
            MACOS_NAME="Catalina"
        elif [[ "$MACOS_MINOR" -eq 14 ]]; then
            MACOS_NAME="Mojave"
        elif [[ "$MACOS_MINOR" -eq 13 ]]; then
            MACOS_NAME="High Sierra"
        elif [[ "$MACOS_MINOR" -eq 12 ]]; then
            MACOS_NAME="Sierra"
        else
            MACOS_NAME="El Capitan or older"
        fi
        ;;
    *)
        MACOS_NAME="Unknown"
        ;;
esac

# Detect Architecture (Apple Silicon vs Intel)
arch_name=$(uname -m)
if [[ "$arch_name" == "arm64" ]]; then
    ARCH_TYPE="Apple Silicon"
elif [[ "$arch_name" == "x86_64" ]]; then
    ARCH_TYPE="Intel"
else
    ARCH_TYPE="other"
fi

# Detect Desktop vs Laptop
model_info=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Model Name" | awk -F': ' '{print $2}')
# Check if it's a laptop (MacBook Air, MacBook Pro, MacBook)
if echo "$model_info" | grep -iq "MacBook"; then
    MODEL_TYPE="Laptop"
else
    MODEL_TYPE="Desktop"
fi

# Detect if Virtual Machine
model_id=$(sysctl -n hw.model 2>/dev/null)
model_name=$(sysctl -n hw.product 2>/dev/null)
if echo "$model_id $model_name" | grep -iqE 'virtual|vmware|parallels|qemu|virtualbox|kvm|xen|bochs|bhyve'; then
    VIRTUALIZATION="Yes"
    # Determine platform
    if   echo "$model_id $model_name" | grep -iq "VirtualMac"; then
        VIRT_PLATFORM="UTM"
    elif echo "$model_id $model_name" | grep -iq "parallels"; then
        VIRT_PLATFORM="Parallels"
    elif echo "$model_id $model_name" | grep -iq "vmware"; then
        VIRT_PLATFORM="VMware"
    elif echo "$model_id $model_name" | grep -iq "virtualbox"; then
        VIRT_PLATFORM="VirtualBox"
    else
        VIRT_PLATFORM="Unknown"
    fi
else
    VIRTUALIZATION="None"
    VIRT_PLATFORM="Physical Device"
fi

# Global Navigation handler
handle_navigation_input() {
    local choice="$1"
    case "$choice" in
        "q"|"Q"|"quit"|"QUIT"|"exit"|"EXIT")
            return_to_menu=false
            interrupted=false
            return $NAV_QUIT
            ;;
        "b"|"B"|"back"|"BACK")
            return_to_menu=false
            interrupted=false
            return $NAV_BACK
            ;;
        *)
            return_to_menu=false
            interrupted=false
            return $NAV_CONT
            ;;
    esac
}

# Resize Terminal window for either Terminal.app or iTerm2
resize_terminal() {
	local cols="$1"
	local rows="$2"
	
	if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
		if [ -n "$cols" ] && [ -n "$rows" ]; then
			# Both specified - resize both (use single -e to avoid timing issues)
			osascript -e "tell application \"Terminal\" to tell front window to set {number of columns, number of rows} to {$cols, $rows}" >/dev/null 2>&1
		elif [ -n "$cols" ]; then
			# Only width specified
			osascript -e "tell application \"Terminal\" to tell front window to set number of columns to $cols" >/dev/null 2>&1
		elif [ -n "$rows" ]; then
			# Only height specified
			osascript -e "tell application \"Terminal\" to tell front window to set number of rows to $rows" >/dev/null 2>&1
		fi
	elif [ "$TERM_PROGRAM" = "iTerm.app" ]; then
		if [ -n "$cols" ] && [ -n "$rows" ]; then
			# Both specified - use single command
			osascript -e "tell application \"iTerm\" to tell current window to tell current session to set {columns, rows} to {$cols, $rows}" >/dev/null 2>&1
		elif [ -n "$cols" ]; then
			osascript -e "tell application \"iTerm\" to tell current window to tell current session to set columns to $cols" >/dev/null 2>&1
		elif [ -n "$rows" ]; then
			osascript -e "tell application \"iTerm\" to tell current window to tell current session to set rows to $rows" >/dev/null 2>&1
		fi
	else
		# ANSI escape sequences
		if [ -n "$cols" ] && [ -n "$rows" ]; then
			printf "\033[8;${rows};${cols}t"
		elif [ -n "$cols" ]; then
			printf "\033[3;${cols}t"
		elif [ -n "$rows" ]; then
			printf "\033[2;${rows}t"
		fi
	fi
}

# Resize Terminal window taller via osascript
function set_terminal_height_to_2200p() {
	if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
		osascript <<-'EOF' >/dev/null 2>&1
			tell application "Terminal"
				set b to bounds of front window
				set leftEdge to item 1 of b
				set topEdge to item 2 of b
				set rightEdge to item 3 of b
				set bottomEdge to item 4 of b
				-- Keep left/top, keep width same (right - left)
				set newBottomEdge to topEdge + 2200 -- increase height by 2200 pixels
				set bounds of front window to {leftEdge, topEdge, rightEdge, newBottomEdge}
			end tell
		EOF
	elif [ "$TERM_PROGRAM" = "iTerm.app" ]; then
		osascript <<-'EOF' >/dev/null 2>&1
			tell application "iTerm"
				tell current window
					set b to bounds
					set leftEdge to item 1 of b
					set topEdge to item 2 of b
					set rightEdge to item 3 of b
					set bottomEdge to item 4 of b
					-- Keep left/top, keep width same (right - left)
					set newBottomEdge to topEdge + 2200 -- increase height by 2200 pixels
					set bounds to {leftEdge, topEdge, rightEdge, newBottomEdge}
				end tell
			end tell
		EOF
	fi
}

# Global Navigation menu
show_navigation_prompt() {
    echo
    echo "${BL}Navigation${NC}: ${GR}⮑${NC}  Continue | ${GR}B${NC} Back | ${GR}^C${NC} Interrupt/Exit | ${GR}Q${NC} Main Menu "
    echo 
}

# Main Menu function
main_menu() {
    while true; do
        trap - SIGINT
        resize_terminal 80 24
        clear
        echo -n "${BO}"
        cat <<'EOF'
                         ___  ___      _      __           _ _      
          _ __  __ _ __ / _ \/ __|  __| |___ / _|__ _ _  _| | |_ ___
         | '  \/ _` / _| (_) \__ \ / _` / -_)  _/ _` | || | |  _(_-<
         |_|_|_\__,_\__|\___/|___/ \__,_\___|_| \__,_|\_,_|_|\__/__/
EOF
        echo -n "${NC}"
        echo "         ${BL}Created by Ryan Summer${NC}  |  ${BL}For macOS 12-26${NC}  |  ${BL}Version 1.4${NC}"
        echo
        echo "${BO}${GR}════════════════════════════════════════════════════════════════════════════════${NC}"
        echo "${BO}Configuration Summary:${NC}"
        echo "  macOS Version:  ${CY}${MACOS_NAME} ${product_version}${NC}"
        echo "  Architecture:   ${CY}${arch_name} (${ARCH_TYPE})${NC}"
        echo "  Machine Type:   ${CY}${model_info} (${MODEL_TYPE})${NC}"
        if [[ "$VIRTUALIZATION" == "Yes" ]]; then
            echo "  Virtualization: ${CY}${VIRTUALIZATION} (${VIRT_PLATFORM})${NC}"
        elif [[ "$VIRTUALIZATION" == "None" ]]; then
            echo "  Virtualization: ${CY}${VIRTUALIZATION} (${VIRT_PLATFORM})${NC}"
        else
            echo "  Virtualization: ${CY}Unknown${NC}"
        fi
        echo "${BO}${GR}════════════════════════════════════════════════════════════════════════════════${NC}"

        show_navigation_prompt # already padded
        read -rp "➡️  ${GR}Press Enter to continue (or ${BL}navigation${NC} ${GR}choice):${NC} " choice
        handle_navigation_input "$choice"
        nav=$?
        if   [[ $nav -eq $NAV_QUIT ]]; then
            return 0
        elif [[ $nav -eq $NAV_BACK ]]; then 
            continue
        fi

        while true; do
            # === HELPER FUNCTIONS FOR VERSION CHECKS ===

            # Check if current macOS version is at least the specified version
            is_at_least() {
                local check_version="$1"
                case "$check_version" in
                    "tahoe")
                        [[ "$MACOS_VERSION" == "tahoe" ]]
                        ;;
                    "sequoia")
                        [[ "$MACOS_VERSION" == "tahoe" || "$MACOS_VERSION" == "sequoia" ]]
                        ;;
                    "sonoma")
                        [[ "$MACOS_VERSION" == "tahoe" || "$MACOS_VERSION" == "sequoia" || "$MACOS_VERSION" == "sonoma" ]]
                        ;;
                    "ventura")
                        [[ "$MACOS_VERSION" != "monterey" && "$MACOS_VERSION" != "catalina" ]]
                        ;;
                    "monterey")
                        [[ "$MACOS_VERSION" != "catalina" ]]
                        ;;
                    *)
                        return 1
                        ;;
                esac
            }

            # Check if running on physical device
            is_physical() {
                [[ "$VIRTUALIZATION" == "none" ]]
            }

            # Check if running on VM
            is_vm() {
                [[ "$VIRTUALIZATION" == "Yes" ]]
            }

            # Check if laptop
            is_laptop() {
                [[ "$MODEL_TYPE" == "Laptop" ]]
            }

            # Check if desktop
            is_desktop() {
                [[ "$MODEL_TYPE" == "Desktop" ]]
            }

            # Function to test if Terminal has Full Disk Access
            has_full_disk_access() {
                # Example: reading ~/Library/Mail requires FDA
                test -r "$HOME/Library/Mail"
            }

            set_terminal_height_to_2200p
            clear
            echo -n "${BO}"
            cat <<'EOF'
                         ___  ___      _      __           _ _      
          _ __  __ _ __ / _ \/ __|  __| |___ / _|__ _ _  _| | |_ ___
         | '  \/ _` / _| (_) \__ \ / _` / -_)  _/ _` | || | |  _(_-<
         |_|_|_\__,_\__|\___/|___/ \__,_\___|_| \__,_|\_,_|_|\__/__/
EOF
            echo -n "${NC}"
            show_navigation_prompt # already padded

            return_to_menu=false
            interrupted=false
            trap 'echo; echo "🛑 ${RE}Interrupted.${NC}"; interrupted=true; sleep 1; break' SIGINT

            echo "🚀 ${BO}Initializing...${NC}"
            echo

            # Close System Preferences/Settings first before opening it again
            echo "🚪 ${GR}Quitting System Preferences/Settings...${NC}"
            osascript -e 'tell application "System Preferences" to quit'
            sleep 1

            # prompt to allow Terminal Full Disk Access
            open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

            # Wait until Terminal is granted Full Disk Access
            echo "🔑 ${GR}Checking if Terminal has Full Disk Access...${NC}"

            until has_full_disk_access; do
                sleep 1
            done

            echo "✅ ${GR}Terminal has Full Disk Access.${NC}"

            # Close System Preferences/Settings again to prevent them from overriding settings we’re about to change
            echo "🚪 ${GR}Quitting System Preferences/Settings...${NC}"

            osascript -e 'tell application "System Preferences" to quit'
            echo
            echo "✅ ${BO}Ready!${NC}"
            echo
            echo "🔑 ${GR}Enter your password to continue${NC}"
            echo

            # return_to_menu=false
            # interrupted=false
            # trap 'echo; echo "🛑 ${RE}Interrupted.${NC}"; interrupted=true; break' SIGINT

            handle_navigation_input
            nav=$?
            if   [[ $nav -eq $NAV_QUIT ]]; then
                return 0
            elif [[ $nav -eq $NAV_BACK ]]; then
                break
            fi

            # Ask for the administrator password upfront
            sudo -v

            # Keep-alive: update existing `sudo` time stamp until this script has finished
            while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
            echo

            echo "📝 ${GR}Writing new preferences...${NC}"
            echo

            # ====== Writing of new preferences starts here ======

            # === macOS TAHOE (26.x) ONLY ===
            if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                echo "🆕 [NEW for ${BL}macOS Tahoe 26]${NC}]"
                defaults write com.apple.Passwords WBSPasswordsAppBackgroundNetworkingEnabled -bool false    # Prevents network telemetry with websites from saved passwords. (This is how icons and names get shown)
                defaults write NSGlobalDomain SLSMenuBarUseBlurredAppearance -bool true    # Shows or disables the menu bar's blurred appearance
                defaults delete NSGlobalDomain AppleDisableTagBasedIconTinting    # Tints folders based on tags (and yes, it seems we have to delete here rather than write)
                defaults write com.apple.Safari NeverUseBackgroundColorInToolbar -bool false    # Shows color in Safari's tab bar
                defaults write com.apple.MobileSMS FilterMessageRequests -bool true   # Screens unknown senders
                defaults write com.apple.SocialLayer SharedWithYouEnabled -bool false   # Screens unknown senders
                defaults write NSGlobalDomain AppleIconAppearanceTheme -string RegularDark    # Enable dark mode on icons
                defaults write NSGlobalDomain NSGlassDiffusionSetting -bool true    # Enable tinted Liquid Glass
                defaults write com.apple.TelephonyUtilities filterUnknownCallersAsNewCallers -bool true   # Filters unknown callers
                defaults write com.apple.Preview PVMarkupToolbarVisibleForPDFs -bool true   # Shows Markup toolbar for PDFs by default
                defaults write com.apple.Preview PVMarkupToolbarVisibleForImages -bool true   # Shows Markup toolbar for images by default
                defaults write com.apple.controlcenter AutoHideMenuBarOption -int 3    # 1 of 2 - Never hides the menu bar when in full screen
                defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool true    # 2 of 2 - Never hides the menu bar when in full screen
                defaults write com.apple.Spotlight PasteboardHistoryEnabled -bool true    # Enable Spotlight's Clipboard Manager/Search
                defaults write com.apple.Spotlight PasteboardHistoryTimeout -int 604800   # Increase Clipboard history from 8hrs to 7 days"
                defaults write com.apple.finder SidebarWidth2 -int 135    # Tahoe 26+
                defaults write com.apple.finder FK_SidebarWidth2 -int 135    # Tahoe 26+
            fi

            # === macOS SEQUOIA (15.x) AND NEWER ===
            if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                echo "🆕 [NEW for ${MA}macOS Sequoia 15${NC}]"
                defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
                defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
                defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool true
                defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false 
                defaults write com.apple.Passwords EnableMenuBarExtra -bool true
                defaults write com.apple.Passwords.MenuBarExtra "NSStatusItem Visible Item-0" -bool true
                
                # disable Apple Intelligence
                # key is different on each machine
                # example: defaults write com.apple.CloudSubscriptionFeatures.optIn 1234567890 -bool false
                # so we dynamically get key from domain by assuming default value is true
                if [[ "$VIRTUALIZATION" == "None" && "$ARCH_TYPE" == "Apple Silicon" ]]; then
                    for key in $(defaults read com.apple.CloudSubscriptionFeatures.optIn 2>/dev/null | grep -E "^\s+[0-9]+ = 1;" | awk '{print $1}'); do
                        defaults write com.apple.CloudSubscriptionFeatures.optIn "$key" -bool false
                    done
                fi
                
                defaults write com.apple.assistant.support "Search Queries Data Sharing Status" -int 2
                defaults write com.apple.universalaccess closeViewZoomScreenShareEnabledKey -bool true 
                defaults write com.apple.universalaccess closeViewZoomIndividualDisplays -bool true
                if [[ "$MODEL_TYPE" == "Laptop" ]]; then
                    defaults write com.apple.controlcenter EnergyModeModule -int 9   # for laptops only
                fi
                defaults write com.apple.bird com.apple.clouddocs.unshared.moveOut.suppress -int 1 # for macOS Sequoia only - for older macOS's use 'defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool true'
                defaults write com.apple.DiskUtility WorkspaceShowAPFSSnapshots -bool true
            fi

            # === macOS SONOMA (14.x) AND NEWER ===
            if [[ "$MACOS_MAJOR" -ge 14 ]]; then
                defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
            fi

            echo "♿️ [Accessibility]" #    ⚠️  ${YE}(Terminal requires Full Disk Access to writ3 changes)${NC}"
            defaults write com.apple.universalaccess closeViewHotkeysEnabled -bool true
            defaults write com.apple.universalaccess closeViewPanningMode -bool false
            defaults write com.apple.universalaccess closeViewZoomFocusFollowModeKey -bool true
            defaults write com.apple.universalaccess closeViewZoomFocusMovement -bool false

            echo "⚓️ [Dock]"
            defaults write com.apple.dock persistent-apps -array    # WARNING: Removes all default app icons from the Dock."
            defaults write com.apple.dock showhidden -bool true 
            defaults write com.apple.dock autohide -bool true
            defaults write com.apple.dock autohide-time-modifier -float 0.0
            defaults write com.apple.dock autohide-delay -float 0.0
            defaults write com.apple.dock mineffect -string scale
            defaults write com.apple.dock minimize-to-application -bool true
            defaults write com.apple.dock show-recents -bool false
            # defaults write com.apple.dock show-process-indicators -bool true   # depreciated/on by default now
            defaults write com.apple.dock tilesize -int 36

            echo "🔄 [Automatic Updates]"
            # sudo softwareupdate --schedule off   # not sure if this works anymore so we use the commands below
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool false
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false

            echo "⚙️  [System & UI]"
            defaults write NSGlobalDomain AppleWindowTabbingMode -string always
            defaults write NSGlobalDomain AppleShowScrollBars -string Always
            defaults write NSGlobalDomain AppleScrollerPagingBehavior -bool true
            defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
            defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
            # defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool true    # Enabled by default
            defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
            if [[ "$MACOS_MAJOR" -ge 12 ]]; then
                # Monterey 12 and above
                defaults -currentHost write com.apple.universalcontrol Disable -bool true
            fi
            if [[ "$MACOS_MAJOR" -eq 10 && "$MACOS_MINOR" -ge 4 && "$MACOS_MINOR" -le 15 ]]; then
                # Tiger 10.4 through Catalina 10.15
                defaults write com.apple.dashboard mcx-disabled -bool true    # depreciated
                sudo launchctl unload /System/Library/LaunchAgents/com.apple.notificationcenterui # depreciated/no longer used on newer macOS's
            fi

            echo "🪄 [Animations]"
            defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
            defaults write com.apple.finder DisableAllAnimations -bool true
            defaults write NSGlobalDomain QLPanelAnimationDuration -float 0.0
            defaults write com.apple.dock expose-animation-duration -float 0.1
            # defaults write NSGlobalDomain com.apple.springing.delay -float 0.2    # enable if desired

            echo "💾 [Disks]"
            defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
            defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
            defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
            defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
            defaults write com.apple.DiskUtility SidebarShowAllDevices -bool true
            defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
            if [[ "$VIRTUALIZATION" == "None" ]]; then
                defaults write /Library/Preferences/com.apple.TimeMachine AutoBackup -bool false    # doesn't work on UTM VMs
            fi

            echo "📁 [Finder]"
            defaults write NSGlobalDomain AppleShowAllExtensions -bool true
            defaults write com.apple.finder ShowPathbar -bool true
            defaults write com.apple.finder ShowStatusBar -bool true
            defaults write com.apple.finder NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow -bool true
            chflags nohidden ~/Library
            defaults write com.apple.finder FinderSpawnTab -bool true
            defaults write com.apple.finder NewWindowTarget -string PfDe
            # defaults write com.apple.finder NewWindowTargetPath file://${HOME}/Desktop/    # not necessary unless choosing a location other than the desktop
            defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
            defaults write com.apple.finder FXDefaultSearchScope -string SCcf
            defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1
            # defaults write com.apple.finder AppleShowAllFiles -bool true    # doesn't seem to be persistent on newer macOS's so i just use ⇧ ⌘ . to manually show hidden files
            defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
            if [[ "$MACOS_MAJOR" -ge 11 && "$MACOS_MAJOR" -le 14 ]] || [[ "$MACOS_MAJOR" -eq 10 && "$MACOS_MINOR" -ge 14 ]]; then
                # Works on Mojave (10.14) through Sonoma (14)
                defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false    # depreciated/for older macOS's
            fi
            defaults write com.apple.finder ShowRecentTags -bool false
            if [[ "$MACOS_MAJOR" -lt 26 ]]; then
                defaults write com.apple.finder SidebarWidth -int 143
                defaults write com.apple.finder FK_SidebarWidth -int 143
            fi
            # add custom keyboard shortcuts for all apps - this needs more testing
            # defaults write com.apple.finder NSUserKeyEquivalents '{
            #     "Get Info" = "@~i";
            #     "Show Inspector" = "@i"; 
            #     "Show Next Tab" = "@~\\U2192";
            #     "Show Previous Tab" = "@~\\U2190";
            # }'

            # customize the Get Info panes
            defaults write com.apple.finder FXInfoPanesExpanded -dict \
                General -bool true \
                Comments -bool false \
                MetaData -bool true \
                Name -bool true \
                OpenWith -bool true \
                Preview -bool false \
                Privileges -bool true

            # Toolbar icons - specific to my prefs so it's commented out
            # defaults write com.apple.finder 'NSToolbar Configuration Browser' '{
            #     "TB Default Item Identifiers" =     (
            #         "com.apple.finder.BACK",
            #         "com.apple.finder.SWCH",
            #         NSToolbarSpaceItem,
            #         "com.apple.finder.ARNG",
            #         "com.apple.finder.SHAR",
            #         "com.apple.finder.LABL",
            #         "com.apple.finder.ACTN",
            #         NSToolbarSpaceItem,
            #         "com.apple.finder.SRCH"
            #     );
            #     "TB Display Mode" = 2;
            #     "TB Icon Size Mode" = 1;
            #     "TB Is Shown" = 1;
            #     "TB Item Identifiers" =     (
            #         "com.apple.finder.BACK",
            #         "com.apple.finder.loc ",
            #         "com.apple.finder.AirD",
            #         "com.apple.finder.CNCT",
            #         "com.apple.finder.NFLD",
            #         "com.apple.finder.SHAR",
            #         "com.apple.finder.SWCH",
            #         NSToolbarSpaceItem,
            #         "com.apple.finder.ACTN",
            #         NSToolbarSpaceItem,
            #         "com.apple.finder.SRCH"
            #     );
            #     "TB Size Mode" = 1;
            # }'

            # Show item info near icons on the desktop and in other icon views
            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
            /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
            # /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

            # Show item info below the icons on the desktop
            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:labelOnBottom true" ~/Library/Preferences/com.apple.finder.plist
            /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:labelOnBottom true" ~/Library/Preferences/com.apple.finder.plist
            # /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:labelOnBottom true" ~/Library/Preferences/com.apple.finder.plist

            # Enable sort-by-name for icons on the desktop and in other icon views
            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist
            /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist
            # /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist

            # Set text size to 14
            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:textSize 14" ~/Library/Preferences/com.apple.finder.plist
            /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:textSize 12" ~/Library/Preferences/com.apple.finder.plist
            # /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:textSize 12" ~/Library/Preferences/com.apple.finder.plist

            # Increase the size of icons on the desktop and in other icon views
            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 72" ~/Library/Preferences/com.apple.finder.plist
            /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 64" ~/Library/Preferences/com.apple.finder.plist
            # /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 72" ~/Library/Preferences/com.apple.finder.plist

            # Increase grid spacing for icons on the desktop and in other icon views
            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 71" ~/Library/Preferences/com.apple.finder.plist
            /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 54" ~/Library/Preferences/com.apple.finder.plist
            # /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 71" ~/Library/Preferences/com.apple.finder.plist

            echo "📸 [Screencapture, Photo & Video]"
            defaults write com.apple.screencapture disable-shadow -bool true
            # defaults read com.apple.screencapture type -string jpg    # enable for jpg if you want, but remember you lose transparency
            defaults write com.apple.screencapture show-thumbnail -bool false
            defaults write com.apple.screencapture showsClicks -bool true
            # defaults write com.apple.screencapture showsCursor -bool false    # I don't use this but it's possible to show the cursor during screenshots if desired
            defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true
            defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
            defaults write com.apple.screencapture include-date -bool false

            echo "🖱️  [Mouse]"
            defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
            defaults write NSGlobalDomain com.apple.mouse.scaling -int 5
            defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string TwoButton

            echo "💻 [TrackPad]"
            defaults write NSGlobalDomain com.apple.trackpad.scaling -int 3
            defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
            defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
            defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
            defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
            defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
            defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
            defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

            echo "⌨️  [Keyboard]"
            defaults write NSGlobalDomain KeyRepeat -int 2
            defaults write NSGlobalDomain InitialKeyRepeat -int 15
            defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
            defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
            defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
            defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
            defaults write com.apple.HIToolbox AppleFnUsageType -int 2
            defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

            echo "📋 [Menu Bar & Control Center]" #    ${YE}(To prevent clutter, I hide all and just use Control Center 👍)${NC}"
            if [[ "$MACOS_MAJOR" -lt 26 ]]; then
                defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool true
            fi
            # defaults -currentHost write com.apple.controlcenter "NSStatusItem Visible BentoBox" -bool true    # Control Center is shown by default in menu bar, but it's possible to hide it if desired
            defaults -currentHost write com.apple.controlcenter WiFi -int 8   # off by default anyway
            defaults -currentHost write com.apple.controlcenter Bluetooth -int 8    # off by default anyway
            defaults -currentHost write com.apple.controlcenter AirDrop -int 8    # off by default anyway
            defaults -currentHost write com.apple.controlcenter FocusModes -int 8   # Don't Show Focus in menu bar. - Use '-int 18' for 'Always Show in Menu Bar' or '-int 2' for 'Show When Active' (Default)
            if [[ "$MACOS_MAJOR" -ge 13 ]]; then
                defaults -currentHost write com.apple.controlcenter StageManager -int 8
            fi
            defaults -currentHost write com.apple.controlcenter ScreenMirroring -int 8
            defaults -currentHost write com.apple.controlcenter Display -int 8
            defaults -currentHost write com.apple.controlcenter Sound -int 8
            defaults -currentHost write com.apple.controlcenter NowPlaying -int 8
            defaults -currentHost write com.apple.controlcenter AccessibilityShortcuts -int 9
            if [[ "$MACOS_MAJOR" -ge 14 ]]; then
                defaults write com.apple.controlcenter MusicRecognition -int 12
            fi
            if [[ "$MACOS_MAJOR" -ge 13 ]]; then
                defaults write com.apple.controlcenter Hearing -int 8
            fi
            defaults write com.apple.controlcenter VoiceControl -int 8
            defaults -currentHost write com.apple.controlcenter UserSwitcher -int 8
            defaults -currentHost write com.apple.controlcenter Siri -int 8
            defaults write com.apple.menuextra.clock ShowSeconds -bool true

            defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.TimeMachine" -bool true
            /usr/libexec/PlistBuddy -c "Add :menuExtras: string '/System/Library/CoreServices/Menu Extras/TimeMachine.menu'" ~/Library/Preferences/com.apple.systemuiserver.plist

            # Show VPN in Menu Bar - only works if you already have a VPN configuration set up
            # commented out for now as I usually run this script before installing a VPN
            # defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.vpn" -bool true
            # /usr/libexec/PlistBuddy -c "Add :menuExtras: string '/System/Library/CoreServices/Menu Extras/VPN.menu'" ~/Library/Preferences/com.apple.systemuiserver.plist

            defaults write com.apple.TextInputMenu visible -bool true
            sudo defaults write /Library/Preferences/com.apple.RemoteManagement.plist LoadRemoteManagementMenuExtra -bool true

            if [[ "$MODEL_TYPE" == "Laptop" ]]; then
                echo "📋 [Menu Bar & Control Center] (For Laptops Only)"
                defaults -currentHost write com.apple.controlcenter Battery -int 3    # always shown
                defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -int 1    # always shown
                defaults -currentHost write com.apple.controlcenter KeyboardBrightness -int 3    # always shown
            fi

            echo "📶 [Connectivity]"
            defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
            defaults -currentHost write com.apple.controlcenter AirplayReceiverEnabled -bool false

            echo "📝 [TextEdit]"
            defaults write com.apple.TextEdit NSWindowTabbingShoudShowTabBarKey-NSWindow-DocumentWindowController-DocumentWindowController-VT-FS -bool true
            defaults write com.apple.TextEdit NSShowAppCentricOpenPanelInsteadOfUntitledFile -bool false
            defaults write com.apple.TextEdit RichText -bool false
            defaults write com.apple.TextEdit NSNavPanelExpandedStateForSaveMode -bool true
            defaults write com.apple.TextEdit NSNavPanelExpandedStateForSaveMode2 -bool true
            defaults write com.apple.TextEdit NSNavPanelFileListModeForSaveMode2 -int 2
            defaults write com.apple.TextEdit NSNavPanelFileLastListModeForSaveModeKey -int 2
            defaults write com.apple.TextEdit NSFixedPitchFontSize -int 14

            echo "👾 [Terminal]"
            defaults write com.apple.Terminal NSWindowTabbingShoudShowTabBarKey-TTWindow-TTWindowController-TTWindowController-VT-FS -bool true
            defaults write com.apple.Terminal UseBrightBold -bool true    # Uses bright colors for bold text"

            echo "📅 [Calendar]"
            defaults write com.apple.iCal "TimeZone support enabled" -bool true    # Enables TimeZone Support

            echo "💬 [Messages]"
            defaults write com.apple.imagent Setting.EnableReadReceipts -bool false    # Disables Send Read Receipts (1 of 2)
            defaults write com.apple.imagent Setting.GlobalReadReceiptsVersionID -int 2    # Disables Send Read Receipts (2 of 2)

            echo "🔎 [Preview]"
            defaults write com.apple.Preview NSWindowTabbingShoudShowTabBarKey-PVWindow-PVWindowController-PVWindowController-VT-FS -bool true    # Shows Tab Bar by default in Preview

            echo "🎵 [Music]"
            defaults write com.apple.Music optimizeSongVolume -bool false    # Disables Sound Check/Normalization

            echo "🗜️  [Archive Utility]"
            defaults write com.apple.archiveutility dearchive-move-after "~/.Trash"
            defaults write com.apple.archiveutility archive-move-after "~/.Trash"
            defaults write com.apple.archiveutility dearchive-reveal-after -bool false

            echo "🌐 [Safari - General]" #    ⚠️  ${YE}(Terminal requires Full Disk Access to read/writ3 changes)${NC}"
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AlwaysShowTabBar -int 1
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowOverlayStatusBar -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowFavoritesBar-v2 -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AlwaysRestoreSessionAtLaunch -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari NewWindowBehavior -int 1
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari NewTabBehavior -int 1
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoOpenSafeDownloads -bool false

            echo "   [Safari - Tabs]"
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari EnableNarrowTabs -bool false
            if [[ "$MACOS_MAJOR" -le 15 ]]; then
                defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowStandaloneTabBar -bool true
            fi
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari CloseTabsAutomatically -bool false
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari CommandClickMakesTabs -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari OpenNewTabsInFront -bool false

            echo "   [Safari - AutoFill]"
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoFillFromAddressBook -bool false
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoFillPasswords -bool false
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoFillCreditCardData -bool false
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoFillMiscellaneousForms -bool false

            echo "   [Safari - Search]"
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari SearchProviderShortName -string DuckDuckGo
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari PrivateSearchEngineUsesNormalSearchEngineToggle -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari SuppressSearchSuggestions -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WebsiteSpecificSearchEnabled -bool false
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari PreloadTopHit -bool false
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowFavoritesUnderSmartSearchField -bool false
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari PrivateSearchEngineUsesNormalSearchEngineToggle -bool true

            echo "   [Safari - Security]"
            defaults write com.apple.Safari.SafeBrowsing SafeBrowsingEnabled -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WarnAboutFraudulentWebsites -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari UseHTTPSOnly -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari PrivateBrowsingRequiresAuthentication -bool true
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari CanPromptForPushNotifications -bool false

            echo "   [Safari - Advanced]"
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowFullURLInSmartSearchField -bool true
            # defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari EnableEnhancedPrivacyInRegularBrowsing -bool true    # enabling this can lead to authorization issues on some websites
            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WebKitPreferences.privateClickMeasurementEnabled -bool false
            defaults write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true

            # Disable custom Spotlight items from being indexed    # 1=on, 0=off
            # commented out since this no longer works in Tahoe
            # Tahoe uses the same domain, but now the keys are 'DisabledUTTypes' & 'EnabledPreferenceRules'
            # echo "🔍 [Spotlight]"
            # defaults read com.apple.spotlight orderedItems -array \
            # '{"enabled" = 1;"name" = "APPLICATIONS";}' \
            # '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
            # '{"enabled" = 0;"name" = "CONTACT";}' \
            # '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
            # '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
            # '{"enabled" = 0;"name" = "DOCUMENTS";}' \
            # '{"enabled" = 0;"name" = "EVENT_TODO";}' \
            # '{"enabled" = 0;"name" = "DIRECTORIES";}' \
            # '{"enabled" = 0;"name" = "FONTS";}' \
            # '{"enabled" = 0;"name" = "IMAGES";}' \
            # '{"enabled" = 0;"name" = "MESSAGES";}' \
            # '{"enabled" = 0;"name" = "MOVIES";}' \
            # '{"enabled" = 0;"name" = "MUSIC";}' \
            # '{"enabled" = 0;"name" = "MENU_OTHER";}' \
            # '{"enabled" = 0;"name" = "PDF";}' \
            # '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
            # '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}' \
            # '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
            # '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
            # '{"enabled" = 0;"name" = "TIPS";}' \
            # '{"enabled" = 0;"name" = "BOOKMARKS";}' \
            # '{"enabled" = 0;"name" = "SOURCE";}'

            # # indexing is commented out here too for now
            # echo
            # echo "🔄 ${GR}Re-indexing Spotlight...${NC}"

            # sleep 1

            # # Load new settings before rebuilding the index
            # killall mds > /dev/null 2>&1
            # sleep 1

            # # Make sure indexing is enabled for the main volume
            # sudo mdutil -i on / > /dev/null
            # sleep 1

            # # Rebuild the index from scratch
            # sudo mdutil -E / > /dev/null
            # sleep 1

            # Keka (Install First) - needs more testing so it's commented out
            # defaults write com.aone.keka # fix array syntax
            #     "com.aone.keka" =     {
            #         7zzComposeOnCompression = 1;
            #         7zzDecomposeOnExtraction = 1;
            #         ActivateOnNewOperation = 1;
            #         AlreadyLovedKeka = 0;
            #         AlreadyShownLoved = 0;
            #         AlwaysAskCompressionPassword = 0;
            #         AppearanceCustomDockTile = 1;
            #         AppearanceDifferentiateTasksCountInDock = 0;
            #         AppearanceShowDockIcon = 1;
            #         AppearanceSquishFaceInDock = 1;
            #         ApplyQuarantineAfterExtraction = 1;
            #         ArchiveSingle = 0;
            #         AskZipUsingAES = 0;
            #         BackgroundQoSOnBattery = 0;
            #         CalculateMD5 = 0;
            #         CloseController = 1;
            #         CreateSFX = 0;
            #         CustomNameMultipleFiles = "";
            #         CustomNameSingleFile = "";
            #         DMGFormat = 0;
            #         DefaultActionToPerform = 0;
            #         DefaultAppDialog = 0;
            #         DefaultExtractLocationController = 2;
            #         DefaultExtractLocationSet = "";
            #         DefaultFormat = ZIP;
            #         DefaultMethod = 3;
            #         DefaultNameController = 1;
            #         DefaultSaveLocationController = 1;
            #         DefaultSaveLocationSet = "";
            #         DefaultSoundCompression = 1;
            #         DefaultSoundExtraction = 2;
            #         DeleteAfterCompression = 1;
            #         DeleteAfterExtraction = 1;
            #         DevLog = 0;
            #         DevLogAll = 0;
            #         DevLogNotifications = 0;
            #         DevLogReader = 0;
            #         DevSaveLog = 0;
            #         Encryption = 1;
            #         ExcludeMacForks = 1;
            #         ExportPassword = 0;
            #         ExtractOnIntermediateFolder = 0;
            #         ExtractionExcludeMacForks = 0;
            #         ExtractionFolderRenameExtension = 1;
            #         ExtractionPreselectedEncoding = "utf-8";
            #         FallbackOption = 0;
            #         FinderAfterCompression = 0;
            #         FinderAfterExtraction = 0;
            #         ForceHFSDMG = 1;
            #         ForceTarballOnCompressionOnly = 1;
            #         GrowlBlocksExit = 1;
            #         IgnoreGZIPName = 0;
            #         KeepExtension = 0;
            #         KekaAskBeforeCancel = 1;
            #         KekaLaunchTimes = 289;
            #         LastLogsCompressionDate = "2025-08-23 04:03:34 +0000";
            #         Legacy19007zSupport = 1;
            #         LetsMoveDialog = 0;
            #         LimitThreads = 0;
            #         MaximumThreads = 0;
            #         NSNavPanelExpandedSizeForOpenMode = "{800, 448}";
            #         NSNavPanelExpandedSizeForSaveMode = "{800, 448}";
            #         NSOSPLastRootDirectory = {length = 1352, bytes = 0x626f6f6b 48050000 00000410 30000000 ... 0c040000 00000000 };
            #         "NSToolbar Configuration AdvancedWindowToolbar" =         {
            #             "TB Display Mode" = 2;
            #             "TB Icon Size Mode" = 1;
            #             "TB Is Shown" = 1;
            #             "TB Size Mode" = 1;
            #         };
            #         "NSToolbar Configuration PreferencesWindowToolbar" =         {
            #             "TB Display Mode" = 1;
            #             "TB Icon Size Mode" = 1;
            #             "TB Is Shown" = 1;
            #             "TB Size Mode" = 1;
            #         };
            #         "NSWindow Frame AdvancedWindow" = "{{1452, 1155}, {336, 408}}";
            #         "NSWindow Frame NSNavPanelAutosaveName" = "560 1535 800 448 0 1080 1920 1055 ";
            #         "NSWindow Frame PreferencesWindow" = "903 393 679 353 0 0 1920 1055 ";
            #         "NSWindow Frame SUStatusFrame" = "760 1770 400 135 0 1080 1920 1055 ";
            #         "NSWindow Frame SUUpdateAlert" = "650 492 620 398 0 0 1920 1055 ";
            #         "NSWindow Frame TasksWindow" = "598 452 404 80 0 0 1920 1055 ";
            #         OldServicesChecked = 1;
            #         QoS = "-1";
            #         QueueCompression = 1;
            #         QueueCompressionLimit = 1;
            #         QueueExtraction = 1;
            #         QueueExtractionLimit = 2;
            #         QueueGlobal = 1;
            #         QueueGlobalLimit = 2;
            #         RemoveBadPasswordExtraction = 1;
            #         RemoveIncompleteExtraction = 0;
            #         RemoveKekaQuarantineIfPossible = 1;
            #         ResizableWindows = 0;
            #         RetryPassword = 1;
            #         ReusePassword = 1;
            #         SUAutomaticallyUpdate = 1;
            #         SUEnableAutomaticChecks = 0;
            #         SUHasLaunchedBefore = 1;
            #         SULastCheckTime = "2025-08-05 19:46:39 +0000";
            #         SUSendProfileInfo = 0;
            #         SelectedMethod = 3;
            #         SelectedTab = ZIP;
            #         SelectedTabDefaults = 1000;
            #         SetAsDefaultApp = 0;
            #         SetModificationDateAfterExtraction = 0;
            #         ShowCompressionPassword = 0;
            #         ShowExtractionPassword = 0;
            #         SilentlyIgnoreTrailingGarbage = 0;
            #         SkipQuarantineSlowdownDetection = 0;
            #         SolidArchive = 1;
            #         SparkleDialog = 1;
            #         TarballSupport = 1;
            #         UnifiedToolbar = 1;
            #         UnrarWithP7ZIP = 0;
            #         UnzipWithUNAR = 1;
            #         Use7zz = 1;
            #         UseCustomNameWithMultipleFiles = 1;
            #         UseDefaultPasswordOnAdvancedWindow = 0;
            #         UseDefaultPasswordOnCompressions = 0;
            #         UseDefaultPasswordOnExtractions = 0;
            #         UseGrowl = 1;
            #         UseHapticFeedback = 1;
            #         UseISO9660 = 0;
            #         UseLongTarballExtension = 1;
            #         UseMultithreadLzip = 1;
            #         UseParentName = 0;
            #         VerifyCompression = 0;
            #         Version = 5613;
            #         WelcomeWindowSafeDelay = "0.03";
            #         ZipUsingAES = 1;
            #     };

            # Kill affected applications
            echo
            echo "🔄 ${GR}Restarting Services...${NC}"

            killall Dock 2>/dev/null || true
            killall Finder 2>/dev/null || true
            killall SystemUIServer 2>/dev/null || true
            killall ControlCenter 2>/dev/null || true
            killall UniversalAccessApp 2>/dev/null || true
            killall cfprefsd 2>/dev/null || true
            sleep 2
            echo
            echo "✅ ${BO}Done!${NC}"
            echo
            echo "⚠️  ${YE}Note that some of these changes require a restart in order to take effect.${NC}"
            echo -n "   ${GR}Would you like to restart now?${NC} [y/N]: "
            read -r response

            handle_navigation_input "$response"
            nav=$?
            if   [[ $nav -eq $NAV_QUIT ]]; then
                echo "❌ ${RE}Canceled.${RE} ${GR}Please restart your Mac manually when ready!${NC}"
                sleep 1
                exit 0
            elif [[ $nav -eq $NAV_BACK ]]; then 
                return 0
            elif [[ "$response" =~ ^[Yy]$ ]]; then 
                echo "🔄 Restarting system..."
                sudo shutdown -r now
            elif [[ $nav -eq $NAV_CONT ]]; then 
                echo "❌ ${RE}Canceled.${RE} ${GR}Please restart your Mac manually when ready!${NC}"
                sleep 1
                exit 0
            fi
        done
    done
}

# Script entry point
main_menu
# intentionally left blank
