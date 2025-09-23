function transcribe --description "Transcribe video/audio with whisper.cpp"
    # Parse arguments
    set -l input_file $argv[1]
    set -l model_size (test -n "$argv[2]" && echo $argv[2] || echo "large-v3")
    set -l max_len (test -n "$argv[3]" && echo $argv[3] || echo "15")  # For brainrot, shorter is better
    
    # Check if input file exists
    if test -z "$input_file"
        echo "Usage: transcribe <input_file> [model_size] [max_segment_length]"
        echo "Model sizes: small, medium, large-v3"
        echo "Example: transcribe video.mp4 large-v3 15"
        return 1
    end
    
    if not test -f "$input_file"
        echo "Error: File '$input_file' not found"
        return 1
    end
    
    # Set model path
    set -l model_path ~/whisper-models/ggml-$model_size.bin
    if not test -f "$model_path"
        echo "Error: Model $model_path not found"
        echo "Download with: wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$model_size.bin -P ~/whisper-models/"
        return 1
    end
    
    # Get base filename without extension
    set -l base_name (string replace -r '\.[^.]+$' '' $input_file)
    set -l temp_wav "$base_name"_temp.wav
    
    # Check if input is video or audio
    set -l file_ext (string match -r '\.[^.]+$' $input_file)
    
    if string match -q -i -r '\.(mp4|mkv|avi|mov|webm)' $file_ext
        echo "📹 Extracting audio from video..."
        ffmpeg -i "$input_file" -ar 16000 -ac 1 -c:a pcm_s16le -y "$temp_wav" -loglevel error
        set -l audio_file "$temp_wav"
    else
        echo "🎵 Processing audio file..."
        set -l audio_file "$input_file"
    end
    
    echo "🧠 Transcribing with whisper.cpp (GPU accelerated)..."
    echo "Model: $model_size | Max length: $max_len chars"
    
    # Run whisper with GPU
    whisper-cpp \
        -m "$model_path" \
        -f "$audio_file" \
        -osrt \
        -ovtt \
        -otxt \
        --gpu \
        -t 8 \
        -p 1 \
        --print-colors \
        --max-len "$max_len" \
        -ml 42
    
    # Clean up temp file if we created one
    if test -f "$temp_wav"
        rm "$temp_wav"
    end
    
    echo ""
    echo "✅ Complete! Generated:"
    echo "  📝 $base_name.srt (for editing)"
    echo "  🌐 $base_name.vtt (for web)"
    echo "  📄 $base_name.txt (plain text)"
end
