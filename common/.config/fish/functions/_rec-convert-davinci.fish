function _rec-convert-davinci --description "Offer to convert recording to DNxHR MOV for DaVinci"
    set -l input $argv[1]
    set -l vf $argv[2]

    echo ""
    echo "Convert to DaVinci? (y/n)"
    read -l confirm
    if test "$confirm" != y
        return
    end

    if test -z "$vf"
        set vf "format=yuv422p"
    end

    set -l output (string replace -r '\.[^.]+$' '.mov' $input)

    echo "Converting to $output (DNxHR HQ) ..."
    ffmpeg -i $input \
        -vf $vf \
        -c:v dnxhd -profile:v dnxhr_hq \
        -c:a pcm_s16le \
        $output

    if test $status -eq 0
        echo "Done: $output"
        echo "Remove original? (y/n)"
        read -l confirm
        if test "$confirm" = y
            rm $input
            echo "Removed $input"
        end
    end
end
