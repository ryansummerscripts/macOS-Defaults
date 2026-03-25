#!/usr/bin/env bash
#                 ___  ___      _      __           _ _      
#  _ __  __ _ __ / _ \/ __|  __| |___ / _|__ _ _  _| | |_ ___
# | '  \/ _` / _| (_) \__ \ / _` / -_)  _/ _` | || | |  _(_-<
# |_|_|_\__,_\__|\___/|___/ \__,_\___|_| \__,_|\_,_|_|\__/__/
# Created by Ryan Summer     For macOS 12-26     Version 1.6
#
# Updated 03/24/2026

# Note:
#   To see all available options not used here or to see what your current preferences are, 
#   check out the 'MacOS Preferences' option in my CLI tool OneCommand (Lite): 
#   https://shop.ryansummer.com/p/onecommand/

# Color Definitions
NC=$'\033[0m'
BO=$'\033[1m'
DM=$'\033[2m'
BK=$'\033[5m'
RE=$'\033[1;31m'
GR=$'\033[1;32m'
YE=$'\033[1;33m'
BL=$'\033[1;34m'
MA=$'\033[1;35m'
CY=$'\033[1;36m'
GY="${BO}${DM}"

# Navigation Codes
NAV_BACK=0
NAV_CONT=1
NAV_QUIT=2

# Misc.
interrupted=false

# Configuration
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
    26) MACOS_NAME="Tahoe" ;;
    15) MACOS_NAME="Sequoia" ;;
    14) MACOS_NAME="Sonoma" ;;
    13) MACOS_NAME="Ventura" ;;
    12) MACOS_NAME="Monterey" ;;
    11) MACOS_NAME="Big Sur" ;;
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
        elif [[ "$MACOS_MINOR" -eq 11 ]]; then
            MACOS_NAME="El Capitan"
        elif [[ "$MACOS_MINOR" -eq 10 ]]; then
            MACOS_NAME="Yosemite"
        elif [[ "$MACOS_MINOR" -eq 9 ]]; then
            MACOS_NAME="Mavericks"
        elif [[ "$MACOS_MINOR" -eq 8 ]]; then
            MACOS_NAME="Mountain Lion"
        elif [[ "$MACOS_MINOR" -eq 7 ]]; then
            MACOS_NAME="Lion"
        else
            MACOS_NAME="Snow Leopard or older"
        fi
        ;;
    *) MACOS_NAME="Unknown" ;;
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
            return $NAV_QUIT
            ;;
        "b"|"B"|"back"|"BACK")
            interrupted=false
            return $NAV_BACK
            ;;
        *)
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
# echo formatting
echo_centered() {
    local text="$1"
    local width=$(tput cols)  # Get current terminal width

    # Remove ANSI color codes to get actual visible length
    local visible_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_length=${#visible_text}
    local padding=$(( (width - text_length) / 2 ))
    
    printf "%${padding}s%b\n" "" "$text"
}
echo_n_centered() {
    local text="$1"
    local width=$(tput cols)  # Get current terminal width

    # Remove ANSI color codes to get actual visible length
    local visible_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_length=${#visible_text}
    local padding=$(( (width - text_length) / 2 ))
    
    printf "%${padding}s%b" "" "$text"
}
# ASCII headers
display_macOS_Defaults_header() {
    echo -n "${BO}"
    cat <<'EOF'
                           ___  ___      _      __           _ _      
            _ __  __ _ __ / _ \/ __|  __| |___ / _|__ _ _  _| | |_ ___
           | '  \/ _` / _| (_) \__ \ / _` / -_)  _/ _` | || | |  _(_-<
           |_|_|_\__,_\__|\___/|___/ \__,_\___|_| \__,_|\_,_|_|\__/__/
EOF
    echo -n "${NC}"
    echo_centered "${BL}Created by Ryan Summer${NC}  |  ${BL}For macOS 12-26${NC}  |  ${BL}Version 1.6${NC}"
}
display_macOS_Defaults_header_for_130px() {
    echo -n "${BO}"
    cat <<'EOF'
                                                    ___  ___      _      __           _ _      
                                     _ __  __ _ __ / _ \/ __|  __| |___ / _|__ _ _  _| | |_ ___
                                    | '  \/ _` / _| (_) \__ \ / _` / -_)  _/ _` | || | |  _(_-<
                                    |_|_|_\__,_\__|\___/|___/ \__,_\___|_| \__,_|\_,_|_|\__/__/
EOF
    echo -n "${NC}"
    echo_centered "${BL}Created by Ryan Summer${NC}  |  ${BL}For macOS 12-26${NC}  |  ${BL}Version 1.6${NC}"
}
show_navigation_prompt_for_80x24_centered() {
    echo
    echo_centered "${BL}Navigation:${NC} ${GR}⮑${NC}  Continue | ${GR}B${NC} Back | ${GR}^C${NC} Interrupt/Exit | ${GR}Q${NC} Main Menu"
    echo 
}

# Main Menu function
main_menu() {
    while true; do
        trap - SIGINT
        resize_terminal 80 24
        clear
        display_macOS_Defaults_header
        show_navigation_prompt_for_80x24_centered
        echo "${BO}${GR}════════════════════════════════════════════════════════════════════════════════${NC}"
        echo "${BO}Configuration Summary:${NC}"
        echo "  macOS Version:  ${CY}${MACOS_NAME} ${product_version}${NC}"
        echo "  Architecture:   ${CY}${arch_name} (${ARCH_TYPE})${NC}"
        echo "  Machine Type:   ${CY}${model_info} (${MODEL_TYPE})${NC}"
        if [[ "$VIRTUALIZATION" == "Yes" ]] || [[ "$VIRTUALIZATION" == "None" ]]; then
            echo "  Virtualization: ${CY}${VIRTUALIZATION} (${VIRT_PLATFORM})${NC}"
        else
            echo "  Virtualization: ${CY}Unknown${NC}"
        fi
        echo "${BO}${GR}════════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        echo_n_centered "➡️  ${GR}Press Enter to continue (or ${BL}navigation${NC} ${GR}choice):${NC} "
        read -r choice
        handle_navigation_input "$choice"
        nav=$?
        if   [[ $nav -eq $NAV_QUIT ]]; then
            echo_n_centered "❌ ${RE}Invalid choice.${NC} ${BO}Use ^C to exit.${NC} "
            read -r -t 1 -n 1
            continue
        elif [[ $nav -eq $NAV_BACK ]]; then 
            echo_n_centered "❌ ${RE}Nothing to go back to.${NC} ${BO}Use ^C to exit.${NC} "
            read -r -t 1 -n 1
            continue
        fi
        sub_menus
    done
}

# Sub-Menus function
sub_menus() {
    # Step 1: Initialize apps for the first time
    while true; do
        trap 'return' SIGINT
        clear
        display_macOS_Defaults_header
        show_navigation_prompt_for_80x24_centered
        echo_centered "Step 1/4: 🔄 ${BO}Initialize Apps${NC}"
        echo
        echo_centered "${YE}In order to ensure certain preferences are persistent upon restart,"
        echo_centered "we need to first initialize these apps for the first time:${NC}"
        echo_centered "${GY}Passwords, Preview, Archive Utility, QuickTime and TextEdit${NC}"
        echo
        echo_centered "${GR}Would you like to automatically open these apps now?${NC}"
        echo_centered "${GY}This will open three existing .txt, .pdf & .mov files that"
        echo_centered "are shipped with every macOS version (12-26).${NC}"
        echo
        echo "${BO}Choose an option:${NC}"
        echo " 1) ${GR}Yes, open and initialize apps for me${NC}"
        echo " ${GR}⮑ ${NC} ${GR}Skip, I've already opened files with them at least once${NC}"
        echo
        echo_n_centered "➡️  ${GR}Choose an option (or ${BL}navigation${NC} ${GR}choice):${NC} "
        read -r choice
        handle_navigation_input "$choice"
        nav=$?
        if   [[ $nav -eq $NAV_QUIT ]]; then
            return 0
        elif [[ $nav -eq $NAV_BACK ]]; then 
            return 0
        fi

        case $choice in
            1) chose_to_open_apps=true ;;
            *) chose_to_open_apps=false ;;
        esac

        if [[ $chose_to_open_apps == "true" ]]; then
            trap - SIGINT
            interrupted=false
            trap 'echo; echo_n_centered "🛑 ${RE}Interrupted.${NC} Press Enter to go back a step: "; interrupted=true; continue' SIGINT
            clear
            display_macOS_Defaults_header
            show_navigation_prompt_for_80x24_centered
            echo_centered "Step 1/4: 🔄 ${BO}Initialize Apps${NC}"
            echo
            echo_centered "${GR}Opening Apps...${NC}"
            echo
            echo "${BO}Once the Passwords app opens:${NC}"
            echo "- Enter your password"
            echo "- Click through the initialization prompts"
            echo "- Toggle on 'Show Passwords in Menu Bar' if desired ${GY}(via settings)${NC}"
            echo "- Wait for the Passwords background service to start"
            echo "- Then come back here and press Enter to automatically quit these apps"
            read -r -t 1 -n 1
            open "/System/Library/CoreServices/Applications/Archive Utility.app"
            open -a "TextEdit" "/etc/hosts"
            open -a "Preview" "/Library/Documentation/License.lpdf"
            open -a "QuickTime Player" "/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/trackpad_placeholder.mov"
            open "/System/Applications/Passwords.app"
            read -r -t 1 -n 1
            open "/System/Applications/Utilities/Terminal.app"
            echo
            echo_n_centered "➡️  ${GR}Press Enter to quit apps and continue (or ${BL}navigation${NC} ${GR}choice):${NC} "
            read -r input
            handle_navigation_input "$input"
            nav=$?
            if   [[ $nav -eq $NAV_QUIT ]]; then 
                return 0
            elif [[ $nav -eq $NAV_BACK ]]; then
                continue
            fi
            echo
            echo_centered "${GR}Quitting Apps...${NC}"
            osascript -e 'quit app "Passwords"' >/dev/null 2>&1
            osascript -e 'quit app "QuickTime Player"' >/dev/null 2>&1
            osascript -e 'quit app "Preview"' >/dev/null 2>&1
            osascript -e 'quit app "TextEdit"' >/dev/null 2>&1
            osascript -e 'quit app "Archive Utility"' >/dev/null 2>&1
            echo
            echo_centered "✅ ${GR}Done${NC}"
            echo
            echo_n_centered "➡️  ${GR}Press Enter to continue to Step 2 (or ${BL}navigation${NC} ${GR}choice):${NC} "
            read -r input
            handle_navigation_input "$input"
            nav=$?
            if   [[ $nav -eq $NAV_QUIT ]]; then 
                return 0
            elif [[ $nav -eq $NAV_BACK ]]; then
                break
            fi
        fi

        # Step 2: Grant Terminal Full Disk Access
        while true; do                
            trap - SIGINT
            interrupted=false
            full_disk_access=$(test -r "$HOME/Library/Mail" > /dev/null 2>&1 && echo "true" || echo "false")
            # Function to test if Terminal has Full Disk Access
            has_full_disk_access() {
                # Example: Reading ~/Library/Mail requires FDA
                test -r "$HOME/Library/Mail"
            }
            if [[ "$full_disk_access" == "false" ]]; then
                trap 'echo; interrupted=true' SIGINT
                clear
                display_macOS_Defaults_header
                show_navigation_prompt_for_80x24_centered
                echo_centered "Step 2/4: 🔄 ${BO}Grant Terminal Full Disk Access${NC}"
                echo
                # Close System Preferences/Settings first before opening it again
                echo "🚪 ${GR}Quitting System Preferences/Settings...${NC}"
                osascript -e 'tell application "System Preferences" to quit'
                sleep 1
                # prompt to allow Terminal Full Disk Access
                echo "🚀 ${GR}Re-opening System Preferences/Settings...${NC}"
                open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
                # Wait until Terminal is granted Full Disk Access
                max_wait_seconds=60  # e.g. 2 minutes
                start_time=$(date +%s)
                echo "🔑 ${GR}Waiting for Terminal to have Full Disk Access...${NC}"
                while ! has_full_disk_access; do
                    current_time=$(date +%s)
                    elapsed=$(( current_time - start_time ))
                    if [ "$elapsed" -ge "$max_wait_seconds" ]; then
                        break
                    fi
                    if [[ $interrupted == "true" ]]; then
                        break
                    fi
                    sleep 1
                done
                trap - SIGINT
                interrupted=false
                trap 'echo; echo_n_centered "🛑 ${RE}Interrupted.${NC} Press Enter to go back a step: "; interrupted=true; break' SIGINT
                if has_full_disk_access; then
                    full_disk_access=true
                    echo "✅ ${GR}Terminal has Full Disk Access.${NC}"
                else
                    echo
                    echo "⏱️  ${YE}Timeout waiting for Full Disk Access.${NC}"
                    echo -n "   Returning to previous step.... "
                    read -r -t 2 -n 1
                    break
                fi
                # Close System Preferences/Settings again to prevent them from overriding settings we’re about to change
                echo "🚪 ${GR}Quitting System Preferences/Settings...${NC}"
                osascript -e 'tell application "System Preferences" to quit'
            else
                trap 'echo; echo_n_centered "🛑 ${RE}Interrupted.${NC} Press Enter to go back a step: "; interrupted=true; break' SIGINT
                clear
                display_macOS_Defaults_header
                show_navigation_prompt_for_80x24_centered
                echo_centered "Step 2/4: ✅ ${GR}Terminal has Full Disk Access.${NC}"
            fi
            echo
            echo_centered "✅ ${GR}Done${NC}"
            echo
            echo_n_centered "➡️  ${GR}Press Enter to continue to Step 3 (or ${BL}navigation${NC} ${GR}choice):${NC} "
            read -r input
            handle_navigation_input "$input"
            nav=$?
            if   [[ $nav -eq $NAV_QUIT ]]; then 
                return 0
            elif [[ $nav -eq $NAV_BACK ]]; then
                break
            fi

            # Step 3: Ensure sudo privileges are active
            while true; do
                if ! sudo -n true 2>/dev/null; then
                    trap - SIGINT
                    interrupted=false
                    trap 'interrupted=true;' SIGINT
                    clear
                    display_macOS_Defaults_header
                    show_navigation_prompt_for_80x24_centered
                    echo_centered "Step 3/4: 🔄 ${BO}Ensure administrator privileges are active${NC}"
                    echo
                    echo_centered "${GR}Please provide your password to run commands as administrator.${NC}"
                    echo
                    echo "🔑 ${GR}Enter your password to continue${NC}"
                    echo "   ${GY}(Press ^C to interrupt)${NC}"
                    echo
                    # Ask for the administrator password upfront
                    if ! sudo -v; then
                        if [[ $interrupted == "true" ]]; then
                            echo_n_centered "🛑 ${RE}Interrupted.${NC} Returning to previous step... "
                        else
                            echo_n_centered "${RE}Returning to previous step...${NC} "
                        fi
                        read -r -t 2 -n 1
                        break
                    fi
                    # Keep-alive: update existing `sudo` time stamp until this script has finished
                    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
                    echo_centered "✅ ${GR}Done${NC}"
                else
                    trap - SIGINT
                    interrupted=false
                    trap 'echo; echo_n_centered "🛑 ${RE}Interrupted.${NC} Press Enter to go back a step: "; interrupted=true; break ' SIGINT
                    clear
                    display_macOS_Defaults_header
                    show_navigation_prompt_for_80x24_centered
                    echo_centered "Step 3/4: ✅ ${GR}Administrator privileges are active${NC}"
                    echo
                    echo_centered "✅ ${GR}Done${NC}"
                fi
                echo
                echo_n_centered "➡️  ${GR}Press Enter to continue to Step 4 (or ${BL}navigation${NC} ${GR}choice):${NC} "
                read -r input
                handle_navigation_input "$input"
                nav=$?
                if   [[ $nav -eq $NAV_QUIT ]]; then 
                    return 0
                elif [[ $nav -eq $NAV_BACK ]]; then
                    break
                fi

                # Step 4: Set Preferences (Confirmation)
                while true; do
                    interrupted=false
                    trap - SIGINT
                    trap 'echo; echo_n_centered "🛑 ${RE}Interrupted.${NC} Press Enter to go back a step: "; interrupted=true; break' SIGINT
                    clear
                    display_macOS_Defaults_header
                    show_navigation_prompt_for_80x24_centered
                    echo_centered "Step 4/4: 🔄 ${BO}Confirm setting new macOS defaults${NC}"
                    echo
                    echo
                    echo
                    echo_centered "⚠️  ${YE}Please close all other windows and quit any other open apps${NC} ⚠️"
                    echo
                    echo_centered "${GY}Preferences will now be set${NC}"
                    echo
                    echo
                    echo
                    echo_n_centered "➡️  ${GR}Type${NC} ${BO}'yes'${NC} ${GR}to confirm/begin (or ${BL}navigation${NC} ${GR}choice):${NC} "
                    read -r confirm
                    handle_navigation_input "$confirm"
                    nav=$?
                    if   [[ $nav -eq $NAV_QUIT ]]; then
                        return 0
                    elif [[ $nav -eq $NAV_BACK ]]; then 
                        break
                    fi                        

                    case $confirm in
                        yes|YES)
                            :
                            ;;
                        *)
                            echo_n_centered "❌ ${RE}Invalid choice.${NC} Please try again. "
                            read -r -t 1 -n 1
                            continue
                            ;;
                    esac

                    # Step 4: Set Preferences (Execution)
                    while true; do
                        interrupted=false
                        trap - SIGINT
                        trap 'echo; echo_n_centered "🛑 ${RE}Interrupted.${NC} Press Enter to go back a step: "; interrupted=true; break 4' SIGINT
                        resize_terminal 130
                        set_terminal_height_to_2200p
                        clear
                        display_macOS_Defaults_header_for_130px
                        show_navigation_prompt_for_80x24_centered
                        echo_centered "Step 4/4: ✅ ${GR}Confirm setting new macOS defaults${NC}"
                        echo
                        echo_centered "📝 ${GR}Writing new preferences...${NC}"
                        echo

                        # === macOS TAHOE (26.x) ONLY ===
                        if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                            echo "----------------------------------------------------------------------------------------------------------------------------------"
                            echo "🆕 [${BO}NEW for${NC} ${BL}macOS Tahoe 26${NC}]"

                            # echo "🌑 Appearance: Enable dark mode on icons ${BL}(Tahoe 26+)${NC}"
                            # defaults write NSGlobalDomain AppleIconAppearanceTheme -string RegularDark

                            # echo "🪟 Appearance: Enable tinted Liquid Glass ${BL}(Tahoe 26+)${NC}"
                            # defaults write NSGlobalDomain NSGlassDiffusionSetting -bool true

                            # echo "🪟 Appearance: Disable 'Tint Folders Based On Tags' ${BL}(Tahoe 26+)${NC}"
                            # defaults delete NSGlobalDomain AppleDisableTagBasedIconTinting

                            echo "📁 Finder: Shrink sidebar width to the minimum ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.finder SidebarWidth2 -int 135
                            defaults write com.apple.finder FK_SidebarWidth2 -int 135

                            echo "💬 Messages: Screen Unknown Senders ${BL}(Tahoe 26+)${NC}" # Screens unknown senders
                            defaults write com.apple.MobileSMS FilterMessageRequests -bool true

                            echo "📋 Menu Bar: Never Hide Menu Bar In Fullscreen ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.controlcenter AutoHideMenuBarOption -int 3
                            defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool true

                            echo "📋 Menu Bar: Show Menu Bar Background ${BL}(Tahoe 26+)${NC}"
                            defaults write NSGlobalDomain SLSMenuBarUseBlurredAppearance -bool true

                            # echo "⏰ Menu Bar: Show Timer in Menu Bar ${BL}(Tahoe 26.2+)${NC}"# Always show
                            # defaults -currentHost write com.apple.controlcenter Timer -int 16

                            echo "🔑 Passwords: Disallow Contacting Websites ${BL}(Tahoe 26+)${NC}" # Prevents network telemetry with websites from saved passwords. (This is how icons and names get shown)
                            defaults write com.apple.Passwords WBSPasswordsAppBackgroundNetworkingEnabled -bool false

                            echo "📞 Phone: Filter Unknown Callers ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.TelephonyUtilities filterUnknownCallersAsNewCallers -bool true

                            echo "📞 Phone: Screen Unknown Callers ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.TelephonyUtilities ReceptionistDisabled -bool false

                            echo "📞 Phone: Enable Hold Assist ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.TelephonyUtilities HoldAssistDetectionEnabled -bool true

                            echo "📞 Phone: Enable Live Voicemail ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.TelephonyUtilities CallScreeningDisabled -bool false

                            echo "✏️  Preview: Show Markup toolbar for images by default ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.Preview PVMarkupToolbarVisibleForPDFs -bool true

                            echo "✏️  Preview: Show Markup toolbar for PDFs by default ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.Preview PVMarkupToolbarVisibleForImages -bool true

                            if [[ "$MACOS_MINOR" -ge 4 ]]; then    # Tahoe 26.4+
                                echo "🗂️  Safari: Disable compact tab layout ${MA}(Sequoia 15 and below)${NC} or ${BL}(Tahoe 26.4+)${NC}"
                                defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowStandaloneTabBar -bool true
                            fi

                            echo "🗂️  Safari: Show Color Tab Bar ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.Safari NeverUseBackgroundColorInToolbar -bool false

                            echo "🚫 Spotlight: Disable all default results (except System Settings & Apps) ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.Spotlight EnabledPreferenceRules -array

                            echo "🚫 Spotlight: Disable 'Show Related Content' ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.Spotlight EnabledPreferenceRules -array \
                                "Custom.relatedContents" \
                                "com.apple.AppStore" \
                                "com.apple.iBooksX" \
                                "com.apple.calculator" \
                                "com.apple.iCal" \
                                "com.apple.AddressBook" \
                                "com.apple.Dictionary" \
                                "com.apple.mail" \
                                "com.apple.MobileSMS" \
                                "com.apple.Notes" \
                                "com.apple.Photos" \
                                "com.apple.podcasts" \
                                "com.apple.reminders" \
                                "com.apple.Safari" \
                                "com.apple.shortcuts" \
                                "com.apple.tips" \
                                "com.apple.VoiceMemos" \
                                "System.documents" \
                                "System.files" \
                                "System.folders" \
                                "System.iphoneApps" \
                                "System.menuItems"
                            
                            echo "🔍 Spotlight: Enable Clipboard Manager/Search ${BL}(Tahoe 26+)${NC}"
                            defaults write com.apple.Spotlight PasteboardHistoryEnabled -bool true

                            echo "🔍 Spotlight: Increase Clipboard history from 8hrs to 7 days ${BL}(Tahoe 26.1+)${NC}"
                            defaults write com.apple.Spotlight PasteboardHistoryTimeout -int 604800 
                        fi

                        # === macOS SEQUOIA (15.x) AND NEWER ===
                        if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                            echo "----------------------------------------------------------------------------------------------------------------------------------"
                            echo "🆕 [${BO}NEW for${NC} ${MA}macOS Sequoia 15${NC}]"

                            echo "🔎 Accessibility: Zoomed Image While Screen Sharing ${MA}(Sequoia 15+)${NC}"
                            defaults write com.apple.universalaccess closeViewZoomScreenShareEnabledKey -bool true

                            echo "🚫 Apple Intelligence: Disable Apple Intelligence ${MA}(Sequoia 15.1+)${NC}"
                            # key is different on each machine
                            # example: defaults write com.apple.CloudSubscriptionFeatures.optIn 1234567890 -bool false
                            # so we dynamically get key from domain by assuming default value is true
                            if [[ "$VIRTUALIZATION" == "None" && "$ARCH_TYPE" == "Apple Silicon" ]]; then
                                for key in $(defaults read com.apple.CloudSubscriptionFeatures.optIn 2>/dev/null | grep -E "^\s+[0-9]+ = 1;" | awk '{print $1}'); do
                                    defaults write com.apple.CloudSubscriptionFeatures.optIn "$key" -bool false
                                done
                            fi

                            # Enable if desired
                            # echo "💾 Disk Utility: Show APFS Snapshots ${MA}(Sequoia 15+)${NC}"
                            # defaults write com.apple.DiskUtility WorkspaceShowAPFSSnapshots -bool true
                            
                            echo "🚫 Finder: Hide Warning before removing from iCloud Drive ${MA}(Sequoia 15+)${NC}"
                            defaults write com.apple.bird com.apple.clouddocs.unshared.moveOut.suppress -int 1

                            echo "🔑 Passwords: Show Passwords In The Menu Bar ${MA}(Sequoia 15+)${NC}"
                            defaults write com.apple.Passwords EnableMenuBarExtra -bool true
                            defaults write com.apple.Passwords.MenuBarExtra "NSStatusItem Visible Item-0" -bool true
                            
                            echo "🕵️‍♂️  Spotlight: Disable 'Help Apple Improve Search' ${MA}(Sequoia 15+)${NC}"
                            defaults write com.apple.assistant.support "Search Queries Data Sharing Status" -int 2

                            echo "🚫 Window Tiling: Disable 'Drag windows to screen edges to tile' ${MA}(Sequoia 15+)${NC}"
                            defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
                            
                            echo "🚫 Window Tiling: Disable 'Drag windows to menu bar to fill screen' ${MA}(Sequoia 15+)${NC}"
                            defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false

                            echo "🪟 Window Tiling: Enable 'Hold ⌥ key while dragging windows to tile' ${MA}(Sequoia 15+)${NC}"
                            defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool true

                            echo "🚫 Window Tiling: Disable 'Tiled windows have margins' ${MA}(Sequoia 15+)${NC}"
                            defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

                            # Enable if you prefer not to access this via Control Center
                            # if [[ "$MODEL_TYPE" == "Laptop" ]]; then
                            #     echo "⚡️ Show Low Power Mode in Menu Bar"
                            #     defaults write com.apple.controlcenter EnergyModeModule -int 9   # for laptops only
                            # fi
                        fi

                        # === macOS SONOMA (14.x) AND NEWER ===
                        if [[ "$MACOS_MAJOR" -ge 14 ]]; then
                            echo "----------------------------------------------------------------------------------------------------------------------------------"
                            echo "🆕 [${BO}NEW for${NC} ${GY}${GR}(Sonoma 14)${NC}]"

                            echo "🔎 Accessibility: Zoom Each Display Independently ${GY}${GR}(Sonoma 14+)${NC}"
                            defaults write com.apple.universalaccess closeViewZoomIndividualDisplays -bool true
                            
                            echo "🚫 Desktop: Disable 'click wallpaper to show Desktop' ${GY}${GR}(Sonoma 14+)${NC}"
                            defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

                            echo "🚫 Accessibility: Reduce Motion/Animations ${GY}${GR}(Sonoma 14+)${NC}"  # Reduces certain animations (i.e. the 'bubbly' spotlight search in Tahoe - but also affects mission control)
                            defaults write com.apple.Accessibility ReduceMotionEnabled -bool true
                            defaults write com.apple.universalaccess reduceMotion -bool true

                        fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🖱️  [${BO}Mouse${NC}]"
                        echo "🚫 Disable Natural Scrolling"
                        defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

                        echo "🚀 Increase Tracking Speed beyond default"
                        defaults write NSGlobalDomain com.apple.mouse.scaling -int 5

                        echo "🖱️  Enable secondary button (on bluetooth multi-touch mice)"
                        defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string TwoButton
                        
                        echo "🚫 Disable 'Shake mouse pointer to locate'"
                        defaults write NSGlobalDomain CGDisableCursorLocationMagnification -bool true

                        echo "🚫 Disable the 'Mouse Keys' keyboard shortcut"
                        defaults write com.apple.universalaccess useMouseKeysShortcutKeys -bool false
                        defaults write com.apple.universalaccess mouseDriverIgnoreTrackpad -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "💻 [${BO}TrackPad${NC}]"
                        
                        echo "💨 Increase Tracking Speed"
                        defaults write NSGlobalDomain com.apple.trackpad.scaling -int 3

                        echo "⚙️  Enable Tap To Click"
                        defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

                        echo "⚙️  Enable Two-Finger Tap To Right Click AND Bottom Right Click"
                        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
                        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
                        defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
                        defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
                        defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
                        defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "⌨️  [${BO}Keyboard${NC}]"
                        
                        echo "💨 Speed Up Initial Key Repeat Rate"
                        defaults write NSGlobalDomain KeyRepeat -int 2

                        echo "💨 Speed Up Delay Until Key Repeat"
                        defaults write NSGlobalDomain InitialKeyRepeat -int 15

                        echo "↔️  Allow tab navigation across UI"
                        defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

                        echo "🚫 Disable auto-capitalization"
                        defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

                        echo "🚫 Disable auto-correct"
                        defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

                        echo "🚫 Disable auto-period substitution"
                        defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

                        echo "😌 Fn/🌐 key Shows Emoji & Symbols"
                        defaults write com.apple.HIToolbox AppleFnUsageType -int 2

                        echo "🚫 Disable accent options when a key is held down"
                        defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

                        # echo "🌐 Use F1, F2, etc. keys as standard function keys ${BO}(Requires logging out)${NC}"    # When this option is selected, press the fn key to use the special features printed on each key
                        # defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "⌨️  [${BO}Keyboard Shortcuts${NC}]"
                        
                        echo "🌎 Global: Sets ⌥⌘ + L/R arrows to Show Previous/Next Tab"
                        defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Show Previous Tab" "@~\\U2190"
                        defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Show Next Tab" "@~\\U2192"
                                        
                        # Add domain to custommenu.apps array if not already present
                        if ! defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q "NSGlobalDomain"; then
                            defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "NSGlobalDomain"
                        fi

                        echo "📁 Finder: Swaps the default shortcuts for Get Info and Show/Hide Inspector"
                        defaults write com.apple.finder NSUserKeyEquivalents -dict-add "Get Info" "@~i"
                        defaults write com.apple.finder NSUserKeyEquivalents -dict-add "Show Inspector" "@i"
                        defaults write com.apple.finder NSUserKeyEquivalents -dict-add "Hide Inspector" "@i"

                        # Add domain to custommenu.apps array if not already present
                        if ! defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q "com.apple.finder"; then
                            defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "com.apple.finder"
                        fi

                        echo "🔎 Preview: Sets ⌥⌘ + M to toggle the Markup Toolbar"
                        defaults write com.apple.Preview NSUserKeyEquivalents -dict-add "Hide Markup Toolbar" "@~m"
                        defaults write com.apple.Preview NSUserKeyEquivalents -dict-add "Show Markup Toolbar" "@~m"

                        # Add domain to custommenu.apps array if not already present
                        if ! defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q "com.apple.Preview"; then
                            defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "com.apple.Preview"
                        fi

                        echo "📝 TextEdit: Swaps the default shortcuts for New and Show Fonts"
                        defaults write com.apple.TextEdit NSUserKeyEquivalents -dict-add "New" "@t"
                        defaults write com.apple.TextEdit NSUserKeyEquivalents -dict-add "Show Fonts" "@n"

                        # Add domain to custommenu.apps array if not already present
                        if ! defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q "com.apple.TextEdit"; then
                            defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "com.apple.TextEdit"
                        fi

                        echo "🔎 Find Any File: Swaps the default shortcuts for Rename and Reveal In Finder"
                        defaults write org.tempel.findanyfile NSUserKeyEquivalents -dict-add "Rename" "@r"
                        defaults write org.tempel.findanyfile NSUserKeyEquivalents -dict-add "Reveal in Finder" "@e"
                                        
                        # Add domain to custommenu.apps array if not already present
                        if ! defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q "org.tempel.findanyfile"; then
                            defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "org.tempel.findanyfile"
                        fi

                        echo "📦 Suspicious Package: Sets ⌥⌘ + L/R arrows for Show Previous/Next Tab"
                        defaults write com.mothersruin.SuspiciousPackageApp NSUserKeyEquivalents -dict-add "Show Previous Tab" "@~\\U2190"
                        defaults write com.mothersruin.SuspiciousPackageApp NSUserKeyEquivalents -dict-add "Show Next Tab" "@~\\U2192"
                                        
                        # # Add domain to custommenu.apps array if not already present
                        # if ! defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q "com.mothersruin.SuspiciousPackageApp"; then
                        #     defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "com.mothersruin.SuspiciousPackageApp"
                        # fi

                        echo "📦 Suspicious Package: Sets ⌥⌘ + '[' or ']' for Previous/Next Tab in Package"
                        defaults write com.mothersruin.SuspiciousPackageApp NSUserKeyEquivalents -dict-add "Next Tab in Package" "@~\U005D"
                        defaults write com.mothersruin.SuspiciousPackageApp NSUserKeyEquivalents -dict-add "Previous Tab in Package" "@~\U005B"
                                        
                        # Add domain to custommenu.apps array if not already present
                        if ! defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q "com.mothersruin.SuspiciousPackageApp"; then
                            defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "com.mothersruin.SuspiciousPackageApp"
                        fi

                        echo "📦 Apparency: Sets ⌥⌘ + L/R arrows for Show Previous/Next Tab"
                        defaults write com.mothersruin.Apparency NSUserKeyEquivalents -dict-add "Show Previous Tab" "@~\\U2190"
                        defaults write com.mothersruin.Apparency NSUserKeyEquivalents -dict-add "Show Next Tab" "@~\\U2192"

                        # Add domain to custommenu.apps array if not already present
                        if ! defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null | grep -q "com.mothersruin.Apparency"; then
                            defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "com.mothersruin.Apparency"
                        fi

                        # killall UniversalAccessApp 2>/dev/null || true
                        # killall universalaccessd 2>/dev/null || true
                        # killall SystemUIServer 2>/dev/null || true
                        # killall Finder 2>/dev/null || true

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "💾 [${BO}Disks${NC}]"

                        echo "💾 Show internal hard disks on desktop"
                        defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

                        echo "💾 Show external hard disks on desktop"
                        defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

                        echo "💾 Show removable media on desktop"
                        defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

                        echo "💾 Show mounted servers on desktop"
                        defaults write com.apple.finder ShowMountedServersOnDesktop -bool true

                        echo "💾 Show all devices in Disk Utility"
                        defaults write com.apple.DiskUtility SidebarShowAllDevices -bool true

                        # Disabled as I don't want Disk Utility asking for my password on every launch
                        # echo "💾 Show APFS Snapshots in Disk Utility"
                        # defaults write com.apple.DiskUtility WorkspaceShowAPFSSnapshots -bool true

                        echo "🚫 Disable new disk requests for Time Machine"
                        defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
                        
                        if [[ "$VIRTUALIZATION" == "None" ]]; then
                            echo "🔄 Set Time Machine backup frequency to 'Manually'"     # doesn't work on UTM VMs
                            defaults write /Library/Preferences/com.apple.TimeMachine AutoBackup -bool false
                        fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "⚓️ [${BO}Dock${NC}]"

                        echo "🗑️  Wipe all app icons from Dock ${BO}(for fresh installs)${NC}"    # WARNING: Removes all default app icons from the Dock."
                        defaults write com.apple.dock persistent-apps -array
                        
                        echo "📏 Set Dock size to 38"
                        defaults write com.apple.dock tilesize -int 38

                        if [[ "$VIRTUALIZATION" == "Yes" ]]; then
                            echo "⬅️  Position dock on left of screen"
                            defaults write com.apple.dock orientation -string left
                        fi

                        echo "⚡ Minimize windows using Scale effect instead of Genie"
                        defaults write com.apple.dock mineffect -string scale

                        echo "📥 Minimize windows into their application icon"
                        defaults write com.apple.dock minimize-to-application -bool true

                        echo "🫥 Automatically hide and show the dock"
                        defaults write com.apple.dock autohide -bool true

                        echo "⚡ Make the dock appear faster"
                        defaults write com.apple.dock autohide-time-modifier -float 0.0

                        echo "⚡ Make the dock disappear faster"
                        defaults write com.apple.dock autohide-delay -float 0.0

                        echo "👻 Dim Dock Icons of Hidden Apps"
                        defaults write com.apple.dock showhidden -bool true 

                        echo "🚫 Disable Recent Items in Dock"
                        defaults write com.apple.dock show-recents -bool false

                        # echo "🏀 Animate opening applications"
                        # defaults write com.apple.dock launchanim -bool true    # on by default now

                        # echo "⚪️ Show indicator lights for open apps"    # depreciated/on by default now
                        # defaults write com.apple.dock show-process-indicators -bool true

                        # echo "🚫 Speed Up Drag and Drop Spring Delay on Dock items"    # Speeds up drag and drop spring delay on dock items
                        # defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "⛶  [${BO}Hot Corners${NC}]"

                        echo "🚫 Disable the default bottom right 'Quick Note' Hot Corner"
                        defaults write com.apple.dock wvous-br-corner -int 1

                        # echo "⏾  Enable the bottom right 'Put Display to Sleep' Hot Corner"
                        # defaults write com.apple.dock wvous-br-corner -int 10

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🖥️  [${BO}Desktop, Widgets & Views${NC}]"

                        if [[ "$MACOS_MAJOR" -ge 14 ]]; then
                            echo "🚫 Disable 'click wallpaper to show Desktop' ${GY}${GR}(Sonoma 14+)${NC}"
                            defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

                            echo "🚫 Disable widgets on Desktop ${GY}${GR}(Sonoma 14+)${NC}"
                            defaults write com.apple.WindowManager StandardHideWidgets -bool true

                            killall WindowManager 2>/dev/null || true

                            sleep 1
                        fi

                        echo "ℹ️  Show item info for icons"
                        /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null

                        echo "ℹ️  Show item info below icons"
                        /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:labelOnBottom true" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null
                        
                        echo "🔤 Sort and arrange icons by name"
                        /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy name" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null
                        
                        echo "📏 Set icon text size to 14"
                        /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:textSize 14.000000" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null
                        
                        echo "📏 Set icon size to 72"
                        /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 72.000000" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null

                        echo "📐 Set icon grid spacing to 100"
                        /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100.000000" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null

                        # Refresh cfprefsd & Finder to reflect Finder plist changes
                        killall cfprefsd 2>/dev/null || true
                        killall Finder 2>/dev/null || true

                        sleep 1

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "⚙️  [${BO}System & UI${NC}]"
                        
                        echo "📜 Always show scroll bars"
                        defaults write NSGlobalDomain AppleShowScrollBars -string Always

                        echo "📜 Click in the scroll bar to 'jump to the spot that's clicked'"
                        defaults write NSGlobalDomain AppleScrollerPagingBehavior -bool true

                        echo "🗂️  Always prefer tabs when opening documents"
                        defaults write NSGlobalDomain AppleWindowTabbingMode -string always

                        # echo "⚠️  Always ask to keep changes when closing documents"    # Enabled by default
                        # defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool true

                        echo "🪟 Close windows when quitting an app"
                        defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false

                        echo "🖱️  Double-clicking title bar zooms window"
                        defaults write NSGlobalDomain AppleActionOnDoubleClick -string Maximize

                        echo "🧹 Clean Up Share Menu Extensions"
                        local extensions=(
                            "com.apple.share.System.add-to-safari-reading-list"
                            # "com.apple.CloudSharingUI.CopyLink"    # keep as is
                            "com.apple.Notes.SharingExtension"
                            "com.apple.share.System.add-to-iphoto"
                            "com.apple.reminders.sharingextension"
                            "com.apple.iBooksX.SharingExtension"
                            "com.apple.shortcuts.Run-Workflow"
                            "com.apple.freeform.sharingextension"
                            # "com.apple.CloudSharingUI.CreateiCloudLinkExtension"    # keep as is
                        )
                        for ext in "${extensions[@]}"; do
                            pluginkit -e ignore -i "$ext"
                        done
                        # Also disable Contact Suggestions via the plist
                        defaults write com.apple.Sharing SharingPeopleSuggestionsDisabled -bool true

                        echo "📂 Expand Save Panels by default (1 of 2)"
                        defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

                        echo "📂 Expand Save Panels by default (2 of 2)"
                        defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

                        echo "📂 Set List View for Open Panels by default (1 of 3)"
                        defaults write NSGlobalDomain NSNavPanelFileLastListModeForOpenModeKey -int 2

                        echo "📂 Set List View for Open Panels by default (2 of 3)"
                        defaults write NSGlobalDomain NSNavPanelFileListModeForOpenMode2 -int 2

                        echo "📂 Set List View for Open Panels by default (3 of 3)"
                        defaults write NSGlobalDomain NavPanelFileListModeForOpenMode -int 2

                        echo "📂 Set List View for Save Panels by default (1 of 3)"
                        defaults write NSGlobalDomain NSNavPanelFileLastListModeForSaveModeKey -int 2

                        echo "📂 Set List View for Save Panels by default (2 of 3)"
                        defaults write NSGlobalDomain NSNavPanelFileListModeForSaveMode2 -int 2

                        echo "📂 Set List View for Save Panels by default (3 of 3)"
                        defaults write NSGlobalDomain NavPanelFileListModeForSaveMode -int 2

                        if [[ "$MACOS_MAJOR" -eq 10 && "$MACOS_MINOR" -ge 4 && "$MACOS_MINOR" -le 15 ]]; then
                            # Tiger 10.4 through Catalina 10.15
                            defaults write com.apple.dashboard mcx-disabled -bool true    # depreciated
                            sudo launchctl unload /System/Library/LaunchAgents/com.apple.notificationcenterui    # depreciated/no longer used on newer macOS's
                        fi

                        # if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                        #     echo "----------------------------------------------------------------------------------------------------------------------------------"

                        #     echo "🪟 [${BO}Window Tiling${NC}]"

                        #     echo "🚫 Window Tiling: Disable 'Drag windows to screen edges to tile' ${MA}(Sequoia 15+)${NC}"
                        #     defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
                            
                        #     echo "🚫 Window Tiling: Disable 'Drag windows to menu bar to fill screen' ${MA}(Sequoia 15+)${NC}"
                        #     defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false

                        #     echo "🪟 Window Tiling: Enable 'Hold ⌥ key while dragging windows to tile' ${MA}(Sequoia 15+)${NC}"    # Already the default
                        #     defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool true

                        #     echo "🚫 Window Tiling: Disable 'Tiled windows have margins' ${MA}(Sequoia 15+)${NC}"
                        #     defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
                        # fi

                        # echo "----------------------------------------------------------------------------------------------------------------------------------"

                        # echo "🕹️  [${BO}Mission Control & Spaces${NC}]"    # I don't use spaces so enable/adjust to your preference

                        # echo "🪟 Automatically rearrange Spaces based on most recent use"
                        # defaults write com.apple.dock mru-spaces -bool false    # default is true

                        # echo "🪟 When switching to an app, switch to a Space with open windows for the app"
                        # defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool false    # default is true

                        # echo "🪟 Group windows by application"
                        # defaults write com.apple.dock expose-group-apps -bool true    # default is false

                        # echo "🪟 Displays have separate Spaces"
                        # defaults write com.apple.spaces spans-displays -bool true    # default is false

                        # if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                        #     echo "🪟 Drag windows to top of screen to enter Mission Control ${MA}(Sequoia 15.1+)${NC}"
                        #     defaults write com.apple.dock enterMissionControlByTopWindowDrag -bool false    # default is true
                        # fi


                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "✨ [${BO}Appearance${NC}]"

                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "🌑 Enable dark mode on icons ${BL}(Tahoe 26+)${NC}"
                        #     defaults write NSGlobalDomain AppleIconAppearanceTheme -string RegularDark

                        #     echo "🪟 Enable tinted Liquid Glass ${BL}(Tahoe 26.1+)${NC}"
                        #     defaults write NSGlobalDomain NSGlassDiffusionSetting -bool true
                        # fi

                        echo "📏 Set sidebar icon size to small (in Finder/Settings)"
                        defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1

                        # echo "🪟 Enable 'Reduce Transparency'"    # Reduces transparency on macoOS UI items
                        # defaults write com.apple.universalaccess reduceTransparency -bool true
                        # defaults write com.apple.Accessibility EnhancedBackgroundContrastEnabled -bool true

                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "🚫 Disable 'Tint Folders Based On Tags' ${BL}(Tahoe 26+)${NC}"
                        #     defaults delete NSGlobalDomain AppleDisableTagBasedIconTinting
                        # fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🪄 [${BO}Animations${NC}]"

                        echo "🚫 Disable Automatic Window Animations"
                        defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

                        echo "🚫 Disable Finder Info Window Animations"
                        defaults write com.apple.finder DisableAllAnimations -bool true

                        echo "🚫 Disable QuickLook Animations"
                        defaults write NSGlobalDomain QLPanelAnimationDuration -float 0.0

                        echo "🚀 Speed Up Mission Control Animations"
                        defaults write com.apple.dock expose-animation-duration -float 0.1
                        
                        # echo "🚀 Speed Up Finder's Drag and Drop Spring Delay"    # enable if desired
                        # defaults write NSGlobalDomain com.apple.springing.delay -float 0.2

                        # if [[ "$MACOS_MAJOR" -ge 14 ]]; then
                        #     echo "🚫 Accessibility: Reduce Motion/Animations ${GY}${GR}(Sonoma 14+)${NC}"     # Reduces certain animations (i.e. the 'bubbly' spotlight search in Tahoe - but also affects mission control)
                        #     default write com.apple.Accessibility ReduceMotionEnabled -bool true
                        #     defaults write com.apple.universalaccess reduceMotion -bool true

                        #     echo "Disable 'Auto-play animated images/GIFs"
                        #     default write com.apple.Accessibility ReduceMotionAutoplayAnimatedImagesEnabled -bool true
                        # fi
                        
                        # if [[ "$MACOS_MAJOR" -le 15 ]]; then
                        #     echo "🚫 Disable Launchpad animation when opening/showing ${MA}(Sequoia 15 and below)${NC}"
                        #     default write com.apple.dock springboard-show-duration -int 0

                        #     echo "🚫 Disable Launchpad animation when closing/hiding ${MA}(Sequoia 15 and below)${NC}"
                        #     default write com.apple.dock springboard-hide-duration -int 0

                        #     echo "🚫 Disable Launchpad animation when swiping between pages ${MA}(Sequoia 15 and below)${NC}"
                        #     default write com.apple.dock springboard-page-duration -int 0
                        # fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "📋 [${BO}Finder List View Options] ${GY}(Applies to all Finder, iCloud, and Trash list views)${NC}"

                        echo "🗑️  Remove all .DS_Store files ${BO}(Resets all Finder views)${NC}"
                        echo "   ${GY}This can take 10-30 seconds to find all '.DS_Store' files...${NC}"
                        echo "   ${YE}Using ossascript to ensure all Finder windows are closed during this.${NC}"
                        echo "   ${YE}Please click allow if prompted...${NC}"
                        
                        # in case Finder windows appear in the forefront
                        osascript -e 'tell application "Finder" to close every window'
                        
                        sudo find / -name ".DS_Store" -type f -delete 2>/dev/null

                        # in case a Finder window re-opens in the forefront
                        osascript -e 'tell application "Finder" to close every window'
                        
                        echo "✅ ${GY}.DS_Store files removed.${NC}"
                        
                        echo "📋 Use List View by default"
                        defaults write com.apple.finder FXPreferredViewStyle -string Nlsv

                        echo "🧮 Enable Calculate All Sizes"
                        
                        calculate_sizes_plist_paths=(
                            ":ICloudViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
                            ":ICloudViewSettings:ListViewSettings:calculateAllSizes"
                            ":FK_iCloudListViewSettingsV2:calculateAllSizes"
                            ":StandardViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
                            ":StandardViewSettings:ListViewSettings:calculateAllSizes"
                            ":FK_DefaultListViewSettingsV2:calculateAllSizes"
                            ":FK_StandardViewSettings:ListViewSettings:calculateAllSizes"
                            ":FK_StandardViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
                            ":TrashViewSettings:ExtendedListViewSettingsV2:calculateAllSizes"
                            ":TrashViewSettings:ListViewSettings:calculateAllSizes"
                        )

                        for plist_path in "${calculate_sizes_plist_paths[@]}"; do
                            # /usr/libexec/PlistBuddy -c "Set $plist_path $value" "$plist_file" 2>/dev/null || \
                            /usr/libexec/PlistBuddy -c "Set $plist_path true" "$HOME/Library/Preferences/com.apple.finder.plist" 2>/dev/null || true
                        done

                        # Refresh cfprefsd & Finder to reflect Finder plist changes
                        killall cfprefsd 2>/dev/null || true
                        killall Finder 2>/dev/null || true
                        sleep 1

                        # local plist_paths=()

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "📁 [${BO}Finder Icon View Options] ${GY}(Applies to all Finder, Save Dialogs, and iCloud icon views)${NC}"
                        
                        # echo "📁 Use Icon View by default"
                        # defaults write com.apple.finder FXPreferredViewStyle -string icnv

                        echo "ℹ️  Show item info near icons"
                        /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :ICloudViewSettings:IconViewSettings:showItemInfo true" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null
                        /usr/libexec/PlistBuddy -c "Add :ICloudViewSettings:IconViewSettings:showItemInfo bool true" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null

                        echo "⤵️  Show item info below icons"
                        /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:labelOnBottom true" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:labelOnBottom true" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :ICloudViewSettings:IconViewSettings:labelOnBottom true" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null
                        /usr/libexec/PlistBuddy -c "Add :ICloudViewSettings:IconViewSettings:labelOnBottom bool true" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null

                        echo "🔤 Sort and arrange icons by name"
                        /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy name" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy name" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :ICloudViewSettings:IconViewSettings:arrangeBy name" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null
                        /usr/libexec/PlistBuddy -c "Add :ICloudViewSettings:IconViewSettings:arrangeBy string name" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null

                        echo "📏 Set icon text size to 12"
                        /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:textSize 12" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:textSize 12" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :ICloudViewSettings:IconViewSettings:textSize 12" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null
                        /usr/libexec/PlistBuddy -c "Add :ICloudViewSettings:IconViewSettings:textSize real 12" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null

                        echo "📏 Set icon size to 48"
                        /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 48" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 48" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :ICloudViewSettings:IconViewSettings:iconSize 48" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null
                        /usr/libexec/PlistBuddy -c "Add :ICloudViewSettings:IconViewSettings:iconSize real 48" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null

                        echo "📐 Set icon grid spacing to 29"
                        /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 29" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 29" $HOME/Library/Preferences/com.apple.finder.plist
                        /usr/libexec/PlistBuddy -c "Set :ICloudViewSettings:IconViewSettings:gridSpacing 29" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null
                        /usr/libexec/PlistBuddy -c "Add :ICloudViewSettings:IconViewSettings:gridSpacing real 29" $HOME/Library/Preferences/com.apple.finder.plist 2>/dev/null
                        
                        # Refresh cfprefsd & Finder to reflect Finder plist changes
                        killall cfprefsd 2>/dev/null || true
                        killall Finder 2>/dev/null || true
                        sleep 1

                        echo "----------------------------------------------------------------------------------------------------------------------------------"
                        
                        echo "📁 [${BO}Finder${NC}]"

                        echo "🗂️  Always Show Tab Bar in Finder"
                        defaults write com.apple.finder NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow -bool true

                        echo "🗂️  Open folders in tabs instead of new windows"
                        defaults write com.apple.finder FinderSpawnTab -bool true

                        echo "🏠 New Finder windows show the Desktop folder"
                        defaults write com.apple.finder NewWindowTarget -string PfDe
                        
                        # echo "🏠 Set Desktop folder path for new Finder windows"
                        # defaults write com.apple.finder NewWindowTargetPath file://${HOME}/Desktop/    # not necessary unless choosing a location other than the desktop

                        echo "🚫 Don't show Recent Tags in the Sidebar"
                        defaults write com.apple.finder ShowRecentTags -bool false

                        echo "🛤️  Show Path Bar in Finder"
                        defaults write com.apple.finder ShowPathbar -bool true

                        echo "📊 Show Status Bar in Finder"
                        defaults write com.apple.finder ShowStatusBar -bool true

                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "📁 Finder: Shrink sidebar width to the minimum ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.finder SidebarWidth2 -int 135
                        #     defaults write com.apple.finder FK_SidebarWidth2 -int 135
                        # fi

                        if [[ "$MACOS_MAJOR" -lt 26 ]]; then
                            echo "📁 Finder: Shrink sidebar width to the minimum ${MA}(Sequoia 15 and below)${NC}"
                            defaults write com.apple.finder SidebarWidth -int 143
                            defaults write com.apple.finder FK_SidebarWidth -int 143
                        fi

                        echo "🏷️  Show all filename extensions"
                        defaults write NSGlobalDomain AppleShowAllExtensions -bool true

                        echo "🚫 Disable the warning when changing a file extension"
                        defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

                        # if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                        #     echo "🚫 Hide Warning before removing from iCloud Drive ${MA}(Sequoia 15+)${NC}"
                        #     defaults write com.apple.bird com.apple.clouddocs.unshared.moveOut.suppress -int 1
                        # fi

                        if [[ "$MACOS_MAJOR" -ge 11 && "$MACOS_MAJOR" -le 14 ]] || [[ "$MACOS_MAJOR" -eq 10 && "$MACOS_MINOR" -ge 14 ]]; then
                            echo "🚫 Hide Warning before removing from iCloud Drive ${GY}${GR}(Sonoma 14 and below)${NC}"    # Works on Mojave (10.14) through Sonoma (14)
                            defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false
                        fi

                        echo "🔍 Search the current folder when performing a search"
                        defaults write com.apple.finder FXDefaultSearchScope -string SCcf

                        echo "📚 Show hidden User ~/Library folder by default"
                        chflags nohidden ~/Library 2>/dev/null || true
                        xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

                        # echo "👻 Show hidden files"    # doesn't seem to be persistent on newer macOS's so i just use ⇧ ⌘ . to manually show hidden files
                        # defaults write com.apple.finder AppleShowAllFiles -bool true

                        echo "🔍 Set Custom Get Info Pane Layout"
                        defaults write com.apple.finder FXInfoPanesExpanded -dict \
                            General -bool true \
                            Comments -bool false \
                            MetaData -bool true \
                            Name -bool true \
                            OpenWith -bool true \
                            Preview -bool false \
                            Privileges -bool true

                        # echo "🔍 Set Custom Toolbar Items"   # specific to my prefs so it's commented out
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
                        
                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "♿️ [${BO}Accessibility - Zoom${NC}]" #    ⚠️  ${YE}(Terminal requires Full Disk Access to writ3 changes)${NC}"
                        
                        echo "🔎 Use keyboard shortcuts to zoom"
                        defaults write com.apple.universalaccess closeViewHotkeysEnabled -bool true

                        echo "🔎 Use trackpad gesture to zoom"
                        defaults write com.apple.universalaccess closeViewTrackpadGestureZoomEnabled -bool true

                        echo "🔎 Zoom Continuously with Pointer"
                        defaults write com.apple.universalaccess closeViewPanningMode -bool false

                        if [[ "$MACOS_MAJOR" -ge 14 ]]; then
                            echo "🔎 Zoom Each Display Independently ${GY}${GR}(Sonoma 14+)${NC}"
                            defaults write com.apple.universalaccess closeViewZoomIndividualDisplays -bool true
                        fi

                        # if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                        #     echo "🔎 Show Zoomed Image While Screen Sharing ${MA}(Sequoia 15+)${NC}"
                        #     defaults write com.apple.universalaccess closeViewZoomScreenShareEnabledKey -bool true
                        # fi

                        echo "🔎 Follow keyboard focus 'Always'"
                        defaults write com.apple.universalaccess closeViewZoomFocusFollowModeKey -bool true
                        
                        echo "🔎 Move screen image so focus item is centered"
                        defaults write com.apple.universalaccess closeViewZoomFocusMovement -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "📋 [${BO}Menu Bar${NC}]" # ${GY}(To prevent clutter, hide all and just use Control Center) 👍${NC}"
                        
                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "📋 Menu Bar: Never Hide Menu Bar In Fullscreen ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.controlcenter AutoHideMenuBarOption -int 3
                        #     defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool true
                        
                        #     echo "📋 Menu Bar: Show Menu Bar Background ${BL}(Tahoe 26+)${NC}"
                        #     defaults write NSGlobalDomain SLSMenuBarUseBlurredAppearance -bool true
                        # fi

                        if [[ "$MACOS_MAJOR" -lt 26 ]]; then
                            echo "🖥️  Never Hide Menu Bar In Fullscreen ${MA}(Sequoia 15 and below)${NC}"
                            defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool true
                        fi

                        # echo "🍱 Show Control Center in Menu Bar"    # Control Center is shown by default in menu bar, but it's possible to hide it if desired by setting this to false
                        # defaults -currentHost write com.apple.controlcenter "NSStatusItem Visible BentoBox" -bool true
                        
                        echo "🕒 Display the time with seconds"
                        defaults write com.apple.menuextra.clock ShowSeconds -bool true

                        # echo "🔍 Don't show Spotlight in Menu Bar"
                        # defaults -currentHost write com.apple.controlcenter Spotlight -int 8
                        # defaults -currentHost write com.apple.Spotlight MenuItemHidden -bool true
                        # defaults delete com.apple.Spotlight "NSStatusItem VisibleCC Item-0"

                        # echo "🔮 Don't show Siri in Menu Bar"
                        # defaults -currentHost write com.apple.controlcenter Siri -int 8

                        # if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                        #     echo "🔑 Passwords: Show Passwords In The Menu Bar ${MA}(Sequoia 15+)${NC}"
                        #     defaults write com.apple.Passwords EnableMenuBarExtra -bool true
                        #     defaults write com.apple.Passwords.MenuBarExtra "NSStatusItem Visible Item-0" -bool true
                        # fi

                        # echo "🛜 Don't show WiFi in Menu Bar"    # off by default anyway
                        # defaults -currentHost write com.apple.controlcenter WiFi -int 8

                        # echo "🔵 Don't show Bluetooth in Menu Bar"    # off by default anyway
                        # defaults -currentHost write com.apple.controlcenter Bluetooth -int 8

                        # echo "🌀 Don't show AirDrop in Menu Bar"    # off by default anyway
                        # defaults -currentHost write com.apple.controlcenter AirDrop -int 8

                        # echo "📵 Don't show Focus in Menu Bar"   # Don't Show Focus in menu bar. - Use '-int 18' for 'Always Show in Menu Bar' or '-int 2' for 'Show When Active' (Default)
                        # defaults -currentHost write com.apple.controlcenter FocusModes -int 8
                        
                        # if [[ "$MACOS_MAJOR" -lt 26 ]]; then
                        #     echo "🚀 Don't show Stage Manager in Menu Bar ${MA}(Sequoia 15 and below)${NC}"
                        #     defaults -currentHost write com.apple.controlcenter StageManager -int 8
                        # fi

                        # echo "🖥️  Don't show Screen Mirroring in Menu Bar "
                        # defaults -currentHost write com.apple.controlcenter ScreenMirroring -int 8

                        # echo "🖥️  Don't show Display in Menu Bar"
                        # defaults -currentHost write com.apple.controlcenter Display -int 8

                        # echo "🔊 Don't show Sound in Menu Bar"
                        # defaults -currentHost write com.apple.controlcenter Sound -int 8

                        # echo "🚀 Don't show Now Playing in Menu Bar"
                        # defaults -currentHost write com.apple.controlcenter NowPlaying -int 8

                        # defaults -currentHost write com.apple.controlcenter AccessibilityShortcuts -int 9
                        # if [[ "$MACOS_MAJOR" -ge 14 ]]; then
                        #     defaults write com.apple.controlcenter MusicRecognition -int 12
                        # fi
                        # if [[ "$MACOS_MAJOR" -ge 13 ]]; then
                        #     defaults write com.apple.controlcenter Hearing -int 8
                        # fi
                        
                        # echo "🎤 Don't show Voice Control in Menu Bar"
                        # defaults write com.apple.controlcenter VoiceControl -int 8
                        
                        if [[ "$VIRTUALIZATION" == "Yes" ]]; then
                            echo "👤 Show Fast User Switching in Menu Bar"
                            defaults -currentHost write com.apple.controlcenter UserSwitcher -int 2
                        fi

                        echo "🔤 Show Text Input in Menu Bar"
                        defaults write com.apple.TextInputMenu visible -bool true

                        if [[ "$VIRTUALIZATION" == "None" ]]; then
                            echo "⏳ Show Time Machine in Menu Bar"
                            defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.TimeMachine" -bool true
                            /usr/libexec/PlistBuddy -c "Add :menuExtras: string '/System/Library/CoreServices/Menu Extras/TimeMachine.menu'" ~/Library/Preferences/com.apple.systemuiserver.plist
                            # killall cfprefsd 2>/dev/null || true
                        fi

                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "⏰ Menu Bar: Show Timer in Menu Bar ${BL}(Tahoe 26+)${NC}"
                        #     defaults -currentHost write com.apple.controlcenter Timer -int 16    # Always show
                        # fi

                        # Show VPN in Menu Bar - only works if you already have a VPN configuration set up
                        # commented out for now as I usually run this script before installing a VPN
                        # defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.vpn" -bool true
                        # /usr/libexec/PlistBuddy -c "Add :menuExtras: string '/System/Library/CoreServices/Menu Extras/VPN.menu'" ~/Library/Preferences/com.apple.systemuiserver.plist
                        # killall cfprefsd 2>/dev/null || true

                        echo "🕹️  Show Remote Management in Menu Bar"
                        sudo defaults write /Library/Preferences/com.apple.RemoteManagement.plist LoadRemoteManagementMenuExtra -bool true

                        if [[ "$MODEL_TYPE" == "Laptop" ]]; then
                            echo "📋 [${BO}Menu Bar & Control Center] (For Laptops Only)"
                            
                            echo "🔋 Show Battery in Menu Bar"
                            defaults -currentHost write com.apple.controlcenter Battery -int 3

                            echo "💯 Show Battery Percentage in Menu Bar"
                            defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -int 1

                            echo "⌨️  Show Keyboard Brightness in Menu Bar"
                            defaults -currentHost write com.apple.controlcenter KeyboardBrightness -int 3
                        fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "📶 [${BO}Connectivity${NC}]"
                        
                        if [[ "$MACOS_MAJOR" -ge 12 ]]; then
                            # Monterey 12 and above
                            echo "🚫 Disable Universal Control"
                            defaults -currentHost write com.apple.universalcontrol Disable -bool true
                        fi
                        
                        echo "🚫 Disable AirPlay Receiver"
                        defaults -currentHost write com.apple.controlcenter AirplayReceiverEnabled -bool false
                        
                        echo "🚫 Prevent Photos from opening automatically when devices are plugged in"
                        defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

                        if [[ "$MACOS_MAJOR" -eq 10 && "$MACOS_MINOR" -gt 7 && "$MACOS_MINOR" -le 10 ]]; then    # 10.7 Lion - 10.10 Yosemite
                            echo "🌐 ${GY}Enable AirDrop over Ethernet on unsupported Macs${NC} ${GY}${RE}(depreciated)${NC}"
                            defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
                        fi

                        # echo "----------------------------------------------------------------------------------------------------------------------------------"

                        # echo "🔍 [${BO}Spotlight${NC}]"

                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "🚫 Disable all default results (except System Settings & Apps) ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.Spotlight EnabledPreferenceRules -array

                        #     echo "🚫 Disable 'Show Related Content' ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.Spotlight EnabledPreferenceRules -array \
                        #         "Custom.relatedContents" \
                        #         "com.apple.AppStore" \
                        #         "com.apple.iBooksX" \
                        #         "com.apple.calculator" \
                        #         "com.apple.iCal" \
                        #         "com.apple.AddressBook" \
                        #         "com.apple.Dictionary" \
                        #         "com.apple.mail" \
                        #         "com.apple.MobileSMS" \
                        #         "com.apple.Notes" \
                        #         "com.apple.Photos" \
                        #         "com.apple.podcasts" \
                        #         "com.apple.reminders" \
                        #         "com.apple.Safari" \
                        #         "com.apple.shortcuts" \
                        #         "com.apple.tips" \
                        #         "com.apple.VoiceMemos" \
                        #         "System.documents" \
                        #         "System.files" \
                        #         "System.folders" \
                        #         "System.iphoneApps" \
                        #         "System.menuItems"                                    
                        #     echo "🔍 Enable Clipboard Manager/Search ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.Spotlight PasteboardHistoryEnabled -bool true

                        #     echo "🔍 Increase Clipboard history from 8hrs to 7 days ${BL}(Tahoe 26.1+)${NC}"
                        #     defaults write com.apple.Spotlight PasteboardHistoryTimeout -int 604800 
                        # fi

                        # if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                        #     echo "🚫 Disable 'Help Apple Improve Search' ${MA}(Sequoia 15+)${NC}"
                        #     defaults write com.apple.assistant.support "Search Queries Data Sharing Status" -int 2
                        # fi

                        if [[ "$MACOS_MAJOR" -lt 26 ]]; then
                            echo "----------------------------------------------------------------------------------------------------------------------------------"

                            echo "🔍 [${BO}Spotlight${NC}]"

                            echo "🚫 Disable all default results (except System Settings & Apps) ${MA}(Sequoia 15 and below)${NC}"
                            defaults write com.apple.Spotlight orderedItems -array \
                            '{"enabled" = 1;"name" = "APPLICATIONS";}' \
                            '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
                            '{"enabled" = 0;"name" = "CONTACT";}' \
                            '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
                            '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
                            '{"enabled" = 0;"name" = "DOCUMENTS";}' \
                            '{"enabled" = 0;"name" = "EVENT_TODO";}' \
                            '{"enabled" = 0;"name" = "DIRECTORIES";}' \
                            '{"enabled" = 0;"name" = "FONTS";}' \
                            '{"enabled" = 0;"name" = "IMAGES";}' \
                            '{"enabled" = 0;"name" = "MESSAGES";}' \
                            '{"enabled" = 0;"name" = "MOVIES";}' \
                            '{"enabled" = 0;"name" = "MUSIC";}' \
                            '{"enabled" = 0;"name" = "MENU_OTHER";}' \
                            '{"enabled" = 0;"name" = "PDF";}' \
                            '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
                            '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}' \
                            '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
                            '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
                            '{"enabled" = 0;"name" = "TIPS";}' \
                            '{"enabled" = 0;"name" = "BOOKMARKS";}' \
                            '{"enabled" = 0;"name" = "SOURCE";}'

                            # indexing is commented out here too for now
                            echo "   ${GY}Re-indexing Spotlight...${NC}"

                            sleep 1

                            # Load new settings before rebuilding the index
                            killall mds > /dev/null 2>&1
                            sleep 1

                            # Make sure indexing is enabled for the main volume
                            sudo mdutil -i on / > /dev/null
                            sleep 1

                            # Rebuild the index from scratch
                            sudo mdutil -E / > /dev/null
                            sleep 1

                        fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🔄 [${BO}Automatic Updates${NC}]"
                        
                        # sudo softwareupdate --schedule off   # not sure if this works anymore
                        
                        echo "🚫 Don't Automatically Download macOS Updates"
                        sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
                        
                        echo "🚫 Don't Automatically Install macOS Updates"
                        sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
                        
                        echo "🚫 Don't Automatically Install Config Data"
                        sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool false
                        
                        echo "🚫 Don't Automatically Install Critical Updates"
                        sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
                        
                        if [[ "$MACOS_MAJOR" -lt 15 ]]; then
                            echo "🚫 ${GY}Don't Automatically Check for macOS Updates${NC} ${GY}${RE}(depreciated)${NC}"
                            sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
                        fi

                        # echo "----------------------------------------------------------------------------------------------------------------------------------"

                        # echo "🤖 [${BO}Apple Intelligence${NC}]"

                        # if [[ "$MACOS_MAJOR" -ge 15 ]]; then
                        #     echo "🚫 Disable Apple Intelligence ${MA}(Sequoia 15.1+)${NC}"
                        #     # key is different on each machine
                        #     # example: defaults write com.apple.CloudSubscriptionFeatures.optIn 1234567890 -bool false
                        #     # so we dynamically get key from domain by assuming default value is true
                        #     if [[ "$VIRTUALIZATION" == "None" && "$ARCH_TYPE" == "Apple Silicon" ]]; then
                        #         for key in $(defaults read com.apple.CloudSubscriptionFeatures.optIn 2>/dev/null | grep -E "^\s+[0-9]+ = 1;" | awk '{print $1}'); do
                        #             defaults write com.apple.CloudSubscriptionFeatures.optIn "$key" -bool false
                        #         done
                        #     fi
                        # fi

                        # echo "----------------------------------------------------------------------------------------------------------------------------------"

                        # echo "🔑 [${BO}Passwords${NC}]"
                        
                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "🔑 Passwords: Disallow Contacting Websites ${BL}(Tahoe 26+)${NC}" # Prevents network telemetry with websites from saved passwords. (This is how icons and names get shown)
                        #     defaults write com.apple.Passwords WBSPasswordsAppBackgroundNetworkingEnabled -bool false
                        # fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "📝 [${BO}TextEdit${NC}]"
                        
                        echo "🗂️  Always show Tab Bar in TextEdit"
                        defaults write com.apple.TextEdit NSWindowTabbingShoudShowTabBarKey-NSWindow-DocumentWindowController-DocumentWindowController-VT-FS -bool true
                        
                        echo "📝 Create a new document by default when opening TextEdit"
                        defaults write com.apple.TextEdit NSShowAppCentricOpenPanelInsteadOfUntitledFile -bool false
                        
                        echo "📝 Use Plain Text Mode for TextEdit"
                        defaults write com.apple.TextEdit RichText -bool false

                        echo "📂 Set Default Font Size in TextEdit to 14"
                        defaults write com.apple.TextEdit NSFixedPitchFontSize -int 14

                        echo "📂 Expand Save Panel by Default (1 of 3)"
                        defaults write com.apple.TextEdit NSNavPanelExpandedStateForSaveMode -bool true
                        
                        echo "📂 Expand Save Panel by Default (2 of 3)"
                        defaults write com.apple.TextEdit NSNavPanelExpandedStateForSaveMode2 -bool true

                        echo "📂 Expand Save Panel by Default (3 of 3)"
                        defaults write com.apple.TextEdit NSNavPanelFileLastListModeForSaveModeKey -int 2

                        # Not sure what OS this used to work on...
                        # defaults write com.apple.TextEdit NSNavPanelFileListModeForSaveMode2 -int 2

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "👾 [${BO}Terminal${NC}]"
                        
                        echo "🗂️  Always show Tab Bar in Terminal"
                        defaults write com.apple.Terminal NSWindowTabbingShoudShowTabBarKey-TTWindow-TTWindowController-TTWindowController-VT-FS -bool true

                        echo "🪟 Sets 'Basic' as the startup profile"
                        defaults write com.apple.Terminal "Startup Window Settings" -string Basic

                        echo "🪟 Sets 'Basic' as the default profile"
                        defaults write com.apple.Terminal "Default Window Settings" -string Basic

                        # # echo "⭐️ Use bright colors for bold text"    # Doesn't seem to work
                        # default_profile=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null)
                        # startup_profile=$(defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null)
                        # profiles_to_update=()
                        # [[ -n "$default_profile" ]] && profiles_to_update+=("$default_profile")
                        # [[ -n "$startup_profile" && "$startup_profile" != "$default_profile" ]] && profiles_to_update+=("$startup_profile")

                        # for profile in "${profiles_to_update[@]}"; do
                        #     /usr/libexec/PlistBuddy -c "Set :'Window Settings':'$profile':UseBrightBold bool true" ~/Library/Preferences/com.apple.Terminal.plist 2>/dev/null
                        #     # result=$(/usr/libexec/PlistBuddy -c "Print :'Window Settings':'$profile':UseBrightBold" ~/Library/Preferences/com.apple.Terminal.plist 2>/dev/null)
                        #     # if [[ "$result" == "true" ]]; then 
                        #     #     echo -n "✅"
                        #     # else
                        #     #     echo -n "❌"
                        #     # fi
                        # done

                        echo "📂 Expand Save Panels by default in Terminal"
                        defaults write com.apple.Terminal NSNavPanelExpandedStateForSaveMode -bool true

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "📅 [${BO}Calendar${NC}]"

                        echo "🕛 Enable TimeZone Support"
                        defaults write com.apple.iCal "TimeZone support enabled" -bool true
                        
                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "💬 [${BO}Messages${NC}]"
                        
                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "💬 Screen Unknown Senders ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.imagent Setting.EnableReadReceipts -bool false
                        # fi

                        echo "🚫 Disable Send Read Receipts"
                        defaults write com.apple.imagent Setting.EnableReadReceipts -bool false
                        defaults write com.apple.imagent Setting.GlobalReadReceiptsVersionID -int 2

                        echo "🚫 Disable Automatic Sharing"
                        defaults write com.apple.SocialLayer SharedWithYouEnabled -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🔎 [${BO}Preview${NC}]"

                        echo "🗂️  Always show Tab Bar in Preview"    # Shows Tab Bar by default in Preview
                        defaults write com.apple.Preview NSWindowTabbingShoudShowTabBarKey-PVWindow-PVWindowController-PVWindowController-VT-FS -bool true

                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "✏️  Show Markup toolbar for images by default ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.Preview PVMarkupToolbarVisibleForImages -bool true

                        #     echo "✏️  Show Markup toolbar for PDFs by default ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.Preview PVMarkupToolbarVisibleForPDFs -bool true
                        # fi

                        echo "📂 Expand Save Panels by default in Preview"
                        defaults write com.apple.Preview NSNavPanelExpandedStateForSaveMode -bool true

                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "----------------------------------------------------------------------------------------------------------------------------------"
                        #     echo "📞 [${BO}Phone${NC}]"

                        #     echo "📞 Phone: Filter Unknown Callers ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.TelephonyUtilities filterUnknownCallersAsNewCallers -bool true

                        #     echo "📞 Phone: Screen Unknown Callers ${BL}(Tahoe 26+)"
                        #     defaults write com.apple.TelephonyUtilities ReceptionistDisabled -bool false

                        #     echo "📞 Phone: Enable Hold Assist ${BL}(Tahoe 26+)"
                        #     defaults write com.apple.TelephonyUtilities HoldAssistDetectionEnabled -bool true

                        #     echo "📞 Phone: Enable Live Voicemail ${BL}(Tahoe 26+)${NC}"
                        #     defaults write com.apple.TelephonyUtilities CallScreeningDisabled -bool false
                        # fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🎵 [${BO}Music${NC}]"
                        
                        echo "🚫 Disable Sound Check/Normalization"
                        defaults write com.apple.Music optimizeSongVolume -bool false    # Disables Sound Check/Normalization

                        echo "----------------------------------------------------------------------------------------------------------------------------------"
                        
                        echo "🗜️  [${BO}Archive Utility${NC}]"

                        echo "🗑️  Move archives to trash after expanding"
                        defaults write com.apple.archiveutility dearchive-move-after "~/.Trash"

                        echo "🗑️  Move files to trash after archiving"
                        defaults write com.apple.archiveutility archive-move-after "~/.Trash"
                        
                        echo "🚫 Don't reveal archives after expanding"
                        defaults write com.apple.archiveutility dearchive-reveal-after -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "📸 [${BO}Screen Capture${NC}]"
                        
                        echo "🚫 Disable Screenshot border and shadow"
                        defaults write com.apple.screencapture disable-shadow -bool true
                        
                        # echo "🖼️  Set default Screenshot Format from PNG to JPG"
                        # defaults read com.apple.screencapture type -string jpg    # enable for jpg if you want, but remember, you lose transparency
                        
                        echo "🚫 Disable Screenshot Preview Thumbnails"
                        defaults write com.apple.screencapture show-thumbnail -bool false
                        
                        # echo "🚫 Disable date and time in filenames"
                        # defaults write com.apple.screencapture include-date -bool false

                        # echo "🚫 Don't Show Mouse Pointer in Screenshots"
                        # defaults write com.apple.screencapture showsCursor -bool false    # I don't use this but it's possible to show the cursor during screenshots if desired

                        echo "🎥 Show Mouse Clicks When Screen Recording"
                        defaults write com.apple.screencapture showsClicks -bool true

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🎥 [${BO}QuickTime Player${NC}]"

                        echo "🗂️  Always Show Tab Bar in QuickTime"
                        defaults write com.apple.QuickTimePlayerX NSWindowTabbingShoudShowTabBarKey-NSWindow-MGDocumentWindowController-MGDocumentWindowController-VT-FS -bool true

                        echo "▶️  Auto-play videos when opened with QuickTime Player"
                        defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

                        echo "✨ Set Audio/Movie Recording Quality to 'Maximum' in QuickTime"
                        defaults write com.apple.QuickTimePlayerX MGRecordingCompressionPresetIdentifier -string MGCompressionPresetMaximumQuality

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🌐 [${BO}Safari - General${NC}]" #    ⚠️  ${YE}(Terminal requires Full Disk Access to read/writ3 changes)${NC}"

                        echo "🗂️  Always Show Tab Bar in Safari"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AlwaysShowTabBar -int 1

                        echo "🌐 Show Overlay Status Bar"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowOverlayStatusBar -bool true

                        echo "⭐️ Show Favorites Bar"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowFavoritesBar-v2 -bool true

                        echo "🎞️  Safari opens with all windows from last session"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AlwaysRestoreSessionAtLaunch -bool true

                        echo "🌐 New windows open with Empty Page"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari NewWindowBehavior -int 1

                        echo "🌐 New tabs open with Empty Page"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari NewTabBehavior -int 1
                        
                        echo "🚫 Disable Auto-Opening of 'Safe' Downloads"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoOpenSafeDownloads -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🌐 [${BO}Safari - Tabs${NC}]"
                                    
                        # echo "🗂️  Close Tabs Manually"    # Active by default
                        # defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari CloseTabsAutomatically -bool false
                        
                        # if [[ "$MACOS_MAJOR" -ge 26 ]]; then
                        #     echo "🗂️  Show Color in Tab Bar ${BL}(Tahoe 26+)${NC}"
                        #     defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari NeverUseBackgroundColorInToolbar -bool false
                        # fi

                        echo "🌐 Always show website titles in tabs"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari EnableNarrowTabs -bool false

                        # echo "🗂️  Command + Click opens a link in a new tab"     # Active by default
                        # defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari CommandClickMakesTabs -bool true
                        
                        # echo "🚫 Don't make new tabs or windows active on command + click"     # Active by default
                        # defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari OpenNewTabsInFront -bool false

                        if [[ "$MACOS_MAJOR" -lt 26 ]]; then
                            echo "🚫 Disable compact tab layout ${MA}(Sequoia 15 and below)${NC} or ${BL}(Tahoe 26.4+)${NC}"
                            defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowStandaloneTabBar -bool true
                        fi

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🌐 [${BO}Safari - AutoFill${NC}]"
                        
                        echo "🚫 Disable AutoFill Contacts"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoFillFromAddressBook -bool false
                        
                        echo "🚫 Disable AutoFill User Names & Passwords"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoFillPasswords -bool false
                        
                        echo "🚫 Disable AutoFill Credit Cards"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoFillCreditCardData -bool false
                        
                        echo "🚫 Disable AutoFill Other Forms"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari AutoFillMiscellaneousForms -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🌐 [${BO}Safari - Search${NC}]"
                        
                        echo "🔎 Use DuckDuckGo as default search provider in ALL Browsing"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari SearchProviderShortName -string DuckDuckGo

                        echo "🔎 Private Search Engine Uses Normal Search Engine"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari PrivateSearchEngineUsesNormalSearchEngineToggle -bool true

                        echo "🚫 Disable Search Engine Suggestions"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari SuppressSearchSuggestions -bool true
                        
                        echo "🚫 Disable Safari Suggestions"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari UniversalSearchEnabled -bool false

                        echo "🚫 Disable Previously Visited Website Suggestions"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WebsiteSpecificSearchEnabled -bool false

                        echo "🚫 Disable Preload Top Hit in the background"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari PreloadTopHit -bool false
                        
                        echo "🚫 Disable Favorites Suggestions"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowFavoritesUnderSmartSearchField -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🌐 [${BO}Safari - Security${NC}]"
                        
                        echo "🔒 Enable Safe Browsing"
                        defaults write com.apple.Safari.SafeBrowsing SafeBrowsingEnabled -bool true
                        
                        echo "⚠️  Warn when visiting a fraudulent website"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WarnAboutFraudulentWebsites -bool true

                        echo "🌐 Warn before connecting to a website over HTTP"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari UseHTTPSOnly -bool true
                        
                        echo "🕵️‍♂️  Require password to view locked tabs in Private Browsing"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari PrivateBrowsingRequiresAuthentication -bool true
                        
                        echo "🚫 Disallow Websites To Send Notifications"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari CanPromptForPushNotifications -bool false

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        echo "🌐 [${BO}Safari - Advanced${NC}]"
                        
                        echo "🌐 Show full website URL in address bar"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari ShowFullURLInSmartSearchField -bool true
                        
                        echo "🕵️‍♂️  Use advanced tracking and fingerprinting protection in ALL browsing"    # enabling this can lead to authorization issues on some websites
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari EnableEnhancedPrivacyInRegularBrowsing -bool true
                        
                        echo "🚫 Disallow privacy-preserving measurement of ad effectiveness"
                        defaults write ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari WebKitPreferences.privateClickMeasurementEnabled -bool false
                        
                        echo "🛠  Show features for web developers"
                        defaults write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true

                        echo "----------------------------------------------------------------------------------------------------------------------------------"

                        # Kill affected applications
                        echo
                        echo "🔄 ${GR}Restarting Services...${NC}"

                        killall Dock 2>/dev/null || true
                        killall Finder 2>/dev/null || true
                        killall UniversalAccessApp 2>/dev/null || true
                        killall universalaccessd 2>/dev/null || true
                        killall SystemUIServer 2>/dev/null || true
                        killall ControlCenter 2>/dev/null || true
                        killall Spotlight 2>/dev/null || true
                        killall corespotlightd 2>/dev/null || true
                        killall spotlightknowledged 2>/dev/null || true
                        killall WindowManager 2>/dev/null || true
                        killall Safari 2>/dev/null || true
                        killall Messages 2>/dev/null || true
                        killall imagent 2>/dev/null || true
                        killall Passwords 2>/dev/null || true
                        killall PasswordsMenuBarExtra 2>/dev/null || true
                        killall TextEdit 2>/dev/null || true
                        killall sociallayerd 2>/dev/null || true
                        killall "Archive Utility" 2>/dev/null || true
                        killall Preview 2>/dev/null || true
                        killall cfprefsd 2>/dev/null || true
                        read -r -t 2 -n 1
                        
                        echo
                        echo_centered "✅ ${BO}Done!${NC}"
                        echo
                        echo_centered "⚠️  ${YE}Note that some of these changes require a restart in order to take effect.${NC}"
                        show_navigation_prompt_for_80x24_centered
                        echo_n_centered "${GR}Would you like to restart now?${NC} [y/N]: "
                        read -r response
                        handle_navigation_input "$response"
                        nav=$?
                        if   [[ $nav -eq $NAV_QUIT ]]; then
                            echo
                            echo_n_centered "❌ ${RE}Canceled.${NC} Please restart your Mac manually when ready. "
                            read -r -t 1 -n 1
                            return 0
                        elif [[ $nav -eq $NAV_BACK ]]; then 
                            echo
                            echo_n_centered "❌ ${RE}Canceled.${NC} Please restart your Mac manually when ready. "
                            read -r -t 1 -n 1
                            return 0
                        elif [[ "$response" =~ ^[Yy]$ ]]; then 
                            echo
                            echo_centered "🔄 Restarting system... "
                            echo
                            echo_centered "👋 ${BO}Goodbye${NC}"
                            echo
                            sudo shutdown -r now
                            exit 0
                        elif [[ $nav -eq $NAV_CONT ]]; then 
                            echo
                            echo_n_centered "❌ ${RE}Canceled.${NC} Please restart your Mac manually when ready. "
                            read -r -t 1 -n 1
                            echo
                            echo
                            echo_centered "👋 ${BO}Goodbye${NC}"
                            echo
                            exit 0
                        fi
                    done
                done
            done
        done
    done
}

# Script entry point
main_menu
# intentionally left blank
