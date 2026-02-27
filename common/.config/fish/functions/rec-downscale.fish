function rec-downscale --description "Downscale 4K recording to 1080p using CUDA + lanczos"
    set -l input $argv[1]
    if test -z "$input"
        echo "Usage: rec-downscale <input> [output]"
        return 1
    end

    set -l output $argv[2]
    if test -z "$output"
        set -l base (string replace -r '\.[^.]+$' '' $input)
        set output {$base}-1080p.mp4
    end

    echo "Downscaling $input → $output"

    ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i $input \
        -vf "scale_cuda=1920:1080:interp_algo=lanczos" \
        -c:v hevc_nvenc -preset p7 -cq 20 -b:v 0 \
        $output
end
