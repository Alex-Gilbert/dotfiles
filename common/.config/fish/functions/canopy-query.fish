function canopy-query --description "Query Canopy/EdgeQuake directly"
    if test (count $argv) -eq 0
        echo "Usage: canopy-query \"your question here\" [mode]"
        echo "Modes: hybrid (default), local, global, naive"
        return 1
    end

    set -l question "$argv[1]"
    set -l mode "hybrid"
    if test (count $argv) -ge 2
        set mode "$argv[2]"
    end

    # Find .canopy.toml by walking up
    set -l dir (pwd)
    while test "$dir" != "/"
        if test -f "$dir/.canopy.toml"
            break
        end
        set dir (dirname "$dir")
    end

    if not test -f "$dir/.canopy.toml"
        echo "No .canopy.toml found"
        return 1
    end

    set -l tenant_id (grep 'tenant_id' "$dir/.canopy.toml" | head -1 | string match -r '"([^"]+)"' | tail -1)
    set -l workspace_id (grep 'workspace_id' "$dir/.canopy.toml" | head -1 | string match -r '"([^"]+)"' | tail -1)
    set -l url (grep 'edgequake_url' "$dir/.canopy.toml" | head -1 | string match -r '"([^"]+)"' | tail -1)

    curl -s "$url/api/v1/query" \
        -H "Content-Type: application/json" \
        -H "X-Tenant-Id: $tenant_id" \
        -H "X-Workspace-Id: $workspace_id" \
        -d "{\"query\": \"$question\", \"mode\": \"$mode\"}" | python3 -m json.tool
end
