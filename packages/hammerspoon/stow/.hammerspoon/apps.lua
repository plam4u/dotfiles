local function toggleAppByName(name)
  local app = hs.application.find(name)
  if not app or app:isHidden() then
    hs.application.launchOrFocus(name)
  elseif hs.application.frontmostApplication() ~= app then
    app:activate()
  else
    app:hide()
  end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local function toggleAppByID(bundleID)
  local app = hs.application.applicationsForBundleID(bundleID)[1]
  -- for key, value in pairs(app) do
  --     print(key, " -- ", value)
  -- end
  if not app or app:isHidden() then
    hs.application.launchOrFocusByBundleID(bundleID)
  elseif hs.application.frontmostApplication() ~= app then
    app:activate()
  else
    if bundleID == "company.thebrowser.Browser" then
        hs.eventtap.keyStroke({ "cmd" }, "h", 0, app)
    else
        app:hide()
    end
  end
end

hs.application.enableSpotlightForNameSearches(true)
hs.urlevent.bind("toggle-app-by-id", function(eventName, params)
    -- hs.alert.closeAll()
    -- hs.alert(params.id)
    toggleAppByID(params.id)
end)
hs.urlevent.bind("toggle-app-by-name", function(eventName, params)
    -- hs.alert.closeAll()
    -- hs.alert(params.name)
    toggleAppByName(params.name)
end)


hs.hotkey.bind(mash, "g", function() hs.application.frontmostApplication():hide() end)

hs.hotkey.bind(mash, "w", function() 
    spoon.ArrangeDesktop:createArrangement() 
    -- spoon.ArrangeDesktop:addMenuItems()
end)
hs.hotkey.bind(mash, "q", function() 
    -- hs.alert(spoon.ArrangeDesktop.arrangements)
    spoon.ArrangeDesktop.arrangements = spoon.ArrangeDesktop:_loadConfiguration()
    -- spoon.ArrangeDesktop:arrange(spoon.ArrangeDesktop.arrangements.A) 
    spoon.ArrangeDesktop:arrange("A") 
end)

hs.hotkey.bind(mash, "f", function() toggleAppByName("Finder") end)
hs.hotkey.bind(mash2, "f", function() toggleAppByName("Figma") end)
-- hs.hotkey.bind(mash, "r", function() toggleAppByName("Mail") end)
hs.hotkey.bind(mash, "p", function() toggleAppByName("Preview") end)
hs.hotkey.bind(mash, "x", function() toggleAppByName("Xcode") end)
hs.hotkey.bind(mash, "c", function() toggleAppByID("com.apple.iphonesimulator") end)
hs.hotkey.bind(mash, "v", function() toggleAppByName("YouTube Music") end)
hs.hotkey.bind(mash2, "v", function() toggleAppByName("YouTube") end)
hs.hotkey.bind(mash, "b", function() toggleAppByName("Notes") end)
hs.hotkey.bind(mash, "d", function() toggleAppByName("Calendar") end)
hs.hotkey.bind(mash2, "d", function() toggleAppByName("draw.io") end)
hs.hotkey.bind(mash, "a", function() toggleAppByName("Telegram") end)
hs.hotkey.bind(mash, "z", function() toggleAppByName("Obsidian") end)
hs.hotkey.bind(mash, "s", function() toggleAppByName("Google Chrome") end)
hs.hotkey.bind(mash2, "s", function() toggleAppByName("Safari") end)
hs.hotkey.bind(mash2, "r", function() toggleAppByName("Reminders") end)
-- hs.hotkey.bind(mash2, "t", function() toggleAppByName("Trello") end)
-- hs.hotkey.bind(mash2, "b", function() toggleAppByName("Notion") end)

-- hs.hotkey.bind(mash, "z", function() toggleAppByName("Zeplin") end)
-- hs.hotkey.bind(mash, "y", function() toggleAppByName("Stickies") end)
-- hs.hotkey.bind({'alt', 'shift'}, "m", function() toggleAppByName("Messages") end)
-- hs.hotkey.bind({'alt', 'shift'}, "f", function() toggleAppByName("Figma") end)
-- hs.hotkey.bind({'cmd', 'alt', 'shift'}, "s", function() toggleAppByName("Google Chrome") end)
-- hs.hotkey.bind(mash, "v", function() toggleAppByName("Stickies") end)
-- hs.hotkey.bind(mash, "p", function() toggleAppByName("System Preferences") end)
-- hs.hotkey.bind({'alt'}, "escape", function() toggleAppByName("Alacritty") end)
-- hs.hotkey.bind(mash, "s", function() toggleAppByName("Safari") end)
-- hs.hotkey.bind({'cmd', 'alt', 'shift'}, "s", function() toggleAppByName("Firefox") end)
