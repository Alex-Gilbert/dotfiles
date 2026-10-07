function tu --description 'Attach to (or create) a tuios session named after this directory'
    tuios attach -c (basename (pwd) | string replace -a . _) $argv
end
