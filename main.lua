-- ============================================
-- HUB - Entry Point untuk Multi-Game Support
-- ============================================

-- Load GameList dari GitHub
local Games = loadstring(game:HttpGet("https://raw.githubusercontent.com/slophisticated/twin/main/gamelist.lua"))()

-- Cek Game ID saat ini
local currentGameId = game.GameId
local gameScript = Games[currentGameId]

-- Load script yang sesuai dengan game
if gameScript then
    print("✅ Game ID: " .. currentGameId .. " - Loading script...")
    loadstring(game:HttpGet(gameScript))()
else
    warn("⚠️ Game ID: " .. currentGameId .. " - Script tidak tersedia!")
end