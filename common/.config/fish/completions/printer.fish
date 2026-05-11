function __printer_names
    lpstat -p 2>/dev/null | string replace -rf '^printer (\S+) .*' '$1'
end

function __printer_needs_subcommand
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

function __printer_subcommand_is
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and contains -- $cmd[2] $argv
end

set -l subs help list status default test print clear add web service
complete -c printer -f

complete -c printer -n __printer_needs_subcommand -a help        -d 'show usage'
complete -c printer -n __printer_needs_subcommand -a list        -d 'list printers'
complete -c printer -n __printer_needs_subcommand -a status      -d 'show print queue'
complete -c printer -n __printer_needs_subcommand -a default     -d 'show or set default'
complete -c printer -n __printer_needs_subcommand -a test        -d 'print test page'
complete -c printer -n __printer_needs_subcommand -a print       -d 'print a file'
complete -c printer -n __printer_needs_subcommand -a clear       -d 'cancel jobs'
complete -c printer -n __printer_needs_subcommand -a add         -d 'GUI: add a printer'
complete -c printer -n __printer_needs_subcommand -a web         -d 'open CUPS web UI'
complete -c printer -n __printer_needs_subcommand -a service     -d 'manage cups.service'

complete -c printer -n '__printer_subcommand_is default test clear' -a '(__printer_names)' -d printer
complete -c printer -n '__printer_subcommand_is print' -F

complete -c printer -n '__printer_subcommand_is service' -a 'start stop restart status enable disable'
