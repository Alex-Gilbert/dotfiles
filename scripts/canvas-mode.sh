#!/bin/bash

# Canvas Mode Toggle Script for Huion Kamvas Pro 13
# Place in ~/.config/i3/scripts/

KAMVAS_MODE_FILE="/tmp/kamvas_mode"

# Monitor configurations
MAIN_MONITOR="DP-0"
KAMVAS_MONITOR="HDMI-0"

# Tablet device names (from xinput list)
STYLUS_DEVICE="Tablet Monitor stylus"
PAD_DEVICE="Tablet Monitor pad"
TOUCH_STRIP="Tablet Monitor Touch Strip pad"
DIAL="Tablet Monitor Dial pad"

configure_tablet_buttons() {
    echo "Configuring tablet buttons..."
    
    PAD_DEVICE="Tablet Monitor pad"
    
    if xsetwacom --list devices | grep -q "$PAD_DEVICE"; then
        # Art-focused button layout for canvas mode
        xsetwacom set "$PAD_DEVICE" "Button1" "key ctrl z"      # Undo
        xsetwacom set "$PAD_DEVICE" "Button2" "key ctrl y"      # Redo  
        xsetwacom set "$PAD_DEVICE" "Button3" "key b"           # Brush tool
        xsetwacom set "$PAD_DEVICE" "Button4" "key e"           # Eraser
        xsetwacom set "$PAD_DEVICE" "Button5" "key ctrl s"      # Save
        xsetwacom set "$PAD_DEVICE" "Button6" "key space"       # Hand tool (pan)
        xsetwacom set "$PAD_DEVICE" "Button7" "key ctrl 0"      # Zoom to fit
        xsetwacom set "$PAD_DEVICE" "Button8" "key ctrl plus"   # Zoom in
        
        echo "  ✓ Tablet buttons configured for art workflow"
    else
        echo "  Warning: Pad device not found for button configuration"
    fi
}

toggle_canvas_mode() {
    if [ -f "$KAMVAS_MODE_FILE" ]; then
        # Exit canvas mode - return to normal dual monitor setup
        echo "Exiting canvas mode..."
        
        # Restore dual monitor setup
        xrandr --output $MAIN_MONITOR --primary --mode 3840x2160 --rate 239.99 --pos 0x0 --rotate normal \
               --output $KAMVAS_MONITOR --mode 2560x1440 --pos 3840x0 --rotate left
        
        # Map stylus back to all displays and restore default settings
        if xinput list | grep -q "$STYLUS_DEVICE"; then
            xinput map-to-output "$STYLUS_DEVICE" desktop
            
            # Restore default pressure curve (linear)
            xinput set-prop "$STYLUS_DEVICE" "Wacom Pressurecurve" 0 0 100 100
            xinput set-prop "$STYLUS_DEVICE" "Wacom Pressure Threshold" 26
        fi
        
        # Restore wallpaper
        feh --bg-scale ~/wallpaper.jpg
        
        # Remove mode file
        rm "$KAMVAS_MODE_FILE"
        
        # Send notification
        notify-send "Canvas Mode" "Disabled - Dual monitor restored" -i input-tablet
        
    else
        # Enter canvas mode - configure Kamvas as primary art display
        echo "Entering canvas mode..."
        
        # Configure Kamvas Pro 13 (1920x1080 is the native resolution)
        xrandr --output $KAMVAS_MONITOR --mode 1920x1080 --rate 60 --pos 0x0 --rotate normal \
               --output $MAIN_MONITOR --mode 3840x2160 --rate 239.99 --pos 1920x0 --rotate normal
        
        # Wait for display to stabilize
        sleep 1
        
        # Configure stylus mapping to Kamvas only
        if xinput list | grep -q "$STYLUS_DEVICE"; then
            echo "Configuring stylus..."
            
            # Map to Kamvas display only
            xinput map-to-output "$STYLUS_DEVICE" $KAMVAS_MONITOR
            
            # Configure pressure curve (0-100 scale, adjust to your preference)
            # Format: xinput set-prop "device" "Wacom Pressurecurve" x1 y1 x2 y2
            # Default: 0 0 100 100 (linear)
            # Soft: 0 10 90 100 (easier pressure)
            # Hard: 10 0 100 90 (requires more pressure)
            xinput set-prop "$STYLUS_DEVICE" "Wacom Pressurecurve" 0 10 90 100
            
            # Set pressure threshold (how hard you need to press to register)
            xinput set-prop "$STYLUS_DEVICE" "Wacom Pressure Threshold" 20
            
            # Set proximity threshold (how close pen needs to be to register hover)
            xinput set-prop "$STYLUS_DEVICE" "Wacom Proximity Threshold" 30
            
            # Configure stylus buttons
            # Button 0 = tip (left click), Button 1 = lower button, Button 2 = upper button
            xinput set-prop "$STYLUS_DEVICE" "Wacom button action 1" 1572866  # Right click
            xinput set-prop "$STYLUS_DEVICE" "Wacom button action 2" 1572867  # Middle click
            
            # Disable touch (if tablet has touch and you don't want it)
            xinput set-prop "$STYLUS_DEVICE" "Wacom Enable Touch" 0
            
            # Enable hover click (registers click when pen touches surface)
            xinput set-prop "$STYLUS_DEVICE" "Wacom Hover Click" 1
            
            echo "Stylus mapped to $KAMVAS_MONITOR with optimized pressure curve"

            configure_tablet_buttons
            
        else
            echo "Warning: Stylus device not found. Check connection."
            notify-send "Canvas Mode" "Warning: Stylus not detected" -i dialog-warning
        fi
        
        # Set canvas-friendly wallpaper (solid color or art-friendly image)
        feh --bg-fill ~/.config/i3/canvas-bg.jpg 2>/dev/null || feh --bg-color "#2d2d2d"
        
        # Load color profile for Kamvas if available
        if [ -f ~/.color/kamvas-pro-13.icc ]; then
            xcalib -d :0.0 ~/.color/kamvas-pro-13.icc
        fi

        # Create mode file
        touch "$KAMVAS_MODE_FILE"
        
        # Send notification
        notify-send "Canvas Mode" "Enabled - Kamvas configured for art" -i input-tablet
    fi

}

# Check if devices exist and provide feedback
check_devices() {
    echo "=== Device Detection ==="
    echo "Available displays:"
    xrandr --query | grep " connected"
    
    echo -e "\nTablet devices:"
    xinput list | grep -i "tablet\|stylus\|pad"
    
    echo -e "\nInput devices:"
    xinput list | grep -i huion
}

# Main execution
case "$1" in
    "check")
        check_devices
        ;;
    "toggle"|"")
        toggle_canvas_mode
        ;;
    *)
        echo "Usage: $0 [toggle|check]"
        echo "  toggle: Switch canvas mode on/off"
        echo "  check:  Show detected devices"
        ;;
esac
