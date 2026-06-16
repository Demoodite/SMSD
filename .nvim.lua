local function load_env(path)
    local env = {}
    local f = io.open(path, "r")
    if not f then
        return env
    end
    for line in f:lines() do
        -- skip comments and blank lines
        if not line:match("^%s*#") and not line:match("^%s*$") then
            local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
            if key then
                -- strip optional surrounding quotes
                value = value:match('^"(.*)"$') or value:match("^'(.*)'$") or value
                env[key] = value
            end
        end
    end
    f:close()
    return env
end

local project_root = vim.fn.getcwd()
local env = load_env(project_root .. "/.env")
local container = env.DOCKER_CONTAINER or "ps2dev"

-- Auto-start the container if it's not already running
local function ensure_container()
    local running =
        vim.fn.system("docker inspect --format '{{.State.Running}}' " .. container .. " 2>/dev/null"):gsub("\n", "")

    if running ~= "true" then
        vim.notify("[ps2] Starting container: " .. container, vim.log.levels.INFO)
        vim.fn.system("docker start " .. container)
    end
end

ensure_container()
local capabilities = require("blink.cmp").get_lsp_capabilities()

-- Setup clangd via docker exec into the running container
vim.lsp.config("clangd", {
    cmd = {
        "docker",
        "exec",
        "-i",
        container,
        "clangd",
        "--log=verbose",
        "--query-driver='/usr/local/ps2dev/ee/bin/ee-gcc*,/usr/local/ps2dev/iop/bin/iop-gcc*'",
        "--background-index",
        "--clang-tidy",
    },

    capabilities = capabilities,

    on_attach = function(client, bufnr)
        vim.notify("[ps2] clangd attached via " .. container, vim.log.levels.INFO)
    end,
})
