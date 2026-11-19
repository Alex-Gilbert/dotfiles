function ftu --description 'tuios command panel: sessions here and on hosts; attach, start, kill'
    # tpanel exits 1 when closed without choosing; outside tuios, fall back to a fresh scratch session.
    tpanel; and return
    set -q TUIOS_SESSION; or tuios new
end
