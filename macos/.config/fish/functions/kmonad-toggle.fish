function kmonad-toggle --description 'Stop/start the kmonad Voyager daemon for the built-in keyboard'
    if sudo launchctl print system/local.kmonad >/dev/null 2>&1
        sudo launchctl bootout system/local.kmonad; and echo "kmonad off: built-in keyboard is plain QWERTY"
    else
        sudo launchctl bootstrap system /Library/LaunchDaemons/local.kmonad.plist; and echo "kmonad on: Voyager layout"
    end
end
