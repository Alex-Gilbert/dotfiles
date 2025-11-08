function repeat
    # Check if a count is provided as the first argument
    if not set -q argv[1]
        echo "Usage: <input> | repeat_stdin_file <count>" >&2
        return 1
    end

    # 1. Set variables and create the temporary file
    set -l count $argv[1]
    # Create a unique temporary file path and ensure it's removed on exit
    set -l tmpfile (mktemp)
    trap "rm -f $tmpfile" EXIT

    # 2. Read stdin and redirect it to the temporary file
    # If the file is empty after this, no input was piped.
    cat - > $tmpfile

    # Check if the temporary file is empty (meaning no input was piped)
    if test (stat -c%s $tmpfile 2>/dev/null) -eq 0
        echo "Error: No input provided on stdin." >&2
        # The trap command will handle the file removal
        return 1
    end

    # 3. Repeat the content using a loop and 'cat'
    # 'seq 1 $count' generates the numbers 1, 2, ..., $count
    for i in (seq 1 $count)
        # Use 'cat' to print the contents of the temporary file
        cat $tmpfile
    end

    # The trap command ensures the temporary file is deleted even if the function errors out.
end
