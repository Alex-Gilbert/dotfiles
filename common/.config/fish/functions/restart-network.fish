function restart-network
    sudo modprobe -r igc && sudo modprobe igc
    sudo systemctl restart NetworkManager
end
