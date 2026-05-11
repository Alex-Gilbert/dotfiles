function printer --description 'CUPS printer wrapper'
    set -l cmd $argv[1]
    set -l rest $argv[2..-1]

    switch "$cmd"
        case '' help -h --help
            echo "printer — CUPS wrapper"
            echo
            echo "  list                       list printers (★ = default)"
            echo "  status                     show print queue / jobs"
            echo "  default [<name>]           show or set default printer"
            echo "  test [<name>]              print a test page"
            echo "  print <file> [<name>]      print a file"
            echo "  clear [<name>|all]         cancel jobs (default: all)"
            echo "  add                        launch system-config-printer (GUI)"
            echo "  web                        open CUPS web UI (localhost:631)"
            echo "  service [start|stop|restart|status]   manage cups.service"
            echo
            echo "Tip: set a default once with 'printer default <name>' so you can omit <name> elsewhere."

        case list ls
            set -l def (lpstat -d 2>/dev/null | string replace -r '^system default destination: ' '')
            for line in (lpstat -p 2>/dev/null)
                set -l name (string split ' ' -- $line)[2]
                if test "$name" = "$def"
                    echo "★ $line"
                else
                    echo "  $line"
                end
            end

        case status queue jobs
            set -l jobs (lpstat -o 2>/dev/null)
            if test (count $jobs) -eq 0
                echo "(no jobs in queue)"
            else
                printf '%s\n' $jobs
            end

        case default
            if test (count $rest) -eq 0
                lpstat -d
            else
                lpoptions -d $rest[1]
                and echo "Default printer set to: $rest[1]"
            end

        case test
            set -l target $rest[1]
            set -l testfile /usr/share/cups/data/default-testpage.pdf
            if test -n "$target"
                lp -d $target $testfile
            else
                lp $testfile
            end

        case print
            if test (count $rest) -lt 1
                echo "usage: printer print <file> [<name>]" >&2
                return 2
            end
            set -l file $rest[1]
            set -l target $rest[2]
            if not test -r "$file"
                echo "cannot read: $file" >&2
                return 1
            end
            if test -n "$target"
                lp -d $target -- $file
            else
                lp -- $file
            end

        case clear cancel
            set -l target $rest[1]
            if test -z "$target" -o "$target" = all
                cancel -a
                and echo "Cancelled all jobs on all printers."
            else
                cancel -a $target
                and echo "Cancelled all jobs on $target."
            end

        case add gui
            if not type -q system-config-printer
                echo "system-config-printer not installed. Try: sudo pacman -S system-config-printer" >&2
                return 1
            end
            system-config-printer &
            disown

        case web ui
            xdg-open http://localhost:631 &
            disown

        case service
            set -l action $rest[1]
            switch "$action"
                case '' status
                    systemctl status cups.service
                case start stop restart enable disable
                    sudo systemctl $action cups.service
                case '*'
                    echo "usage: printer service [start|stop|restart|status|enable|disable]" >&2
                    return 2
            end

        case '*'
            echo "unknown command: $cmd" >&2
            printer help
            return 2
    end
end
