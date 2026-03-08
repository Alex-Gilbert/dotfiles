function _rec-webcam-stop --description "Stop background webcam recording"
    set -l pid $argv[1]
    set -l output $argv[2]

    if test -z "$pid"
        return
    end

    kill -INT $pid 2>/dev/null
    wait $pid 2>/dev/null
    echo "Webcam saved: $output"
end
