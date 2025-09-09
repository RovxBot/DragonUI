local addon = _G.DragonUI_Addon
local H = addon.OptionsHelpers or {}

function addon._buildCastbarsFocus()
    return { type='group', name='Focus Castbar', order=3, args={
        enabled = { type='toggle', order=1, name='Enable Focus Castbar', desc='Enable or disable the focus castbar',
            get=function() return addon.db.profile.castbar.focus.enabled end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','enabled','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.enabled=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        x_position = { type='range', order=2, name='X Position', desc='Horizontal position relative to anchor point', min=-1500, max=1500, step=1,
            get=function() return addon.db.profile.castbar.focus.x_position or 0 end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','x_position','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.x_position=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        y_position = { type='range', order=3, name='Y Position', desc='Vertical position relative to anchor point', min=-1500, max=1500, step=1,
            get=function() return addon.db.profile.castbar.focus.y_position or 0 end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','y_position','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.y_position=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        sizeX = { type='range', order=4, name='Width', desc='Width of the focus castbar', min=50, max=400, step=1,
            get=function() return addon.db.profile.castbar.focus.sizeX or 200 end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','sizeX','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.sizeX=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        sizeY = { type='range', order=5, name='Height', desc='Height of the focus castbar', min=5, max=50, step=1,
            get=function() return addon.db.profile.castbar.focus.sizeY or 16 end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','sizeY','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.sizeY=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        scale = { type='range', order=6, name='Scale', desc='Scale of the focus castbar', min=0.5, max=2.0, step=0.1,
            get=function() return addon.db.profile.castbar.focus.scale or 1 end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','scale','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.scale=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        showIcon = { type='toggle', order=7, name='Show Icon', desc='Show the spell icon next to the focus castbar',
            get=function() return addon.db.profile.castbar.focus.showIcon end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','showIcon','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.showIcon=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        sizeIcon = { type='range', order=8, name='Icon Size', desc='Size of the spell icon', min=10, max=50, step=1,
            get=function() return addon.db.profile.castbar.focus.sizeIcon or 20 end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','sizeIcon','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.sizeIcon=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end,
            disabled=function() return not addon.db.profile.castbar.focus.showIcon end },
        text_mode = { type='select', order=9, name='Text Mode', desc='Choose how to display spell text: Simple (centered spell name only) or Detailed (spell name + time)', values={ simple='Simple', detailed='Detailed' },
            get=function() return addon.db.profile.castbar.focus.text_mode or 'detailed' end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','text_mode','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.text_mode=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        precision_time = { type='range', order=10, name='Time Precision', desc='Decimal places for remaining time', min=0, max=3, step=1,
            get=function() return addon.db.profile.castbar.focus.precision_time or 1 end,
            set=function(_,v) addon.db.profile.castbar.focus.precision_time=v end,
            disabled=function() return addon.db.profile.castbar.focus.text_mode=='simple' end },
        precision_max = { type='range', order=11, name='Max Time Precision', desc='Decimal places for total time', min=0, max=3, step=1,
            get=function() return addon.db.profile.castbar.focus.precision_max or 1 end,
            set=function(_,v) addon.db.profile.castbar.focus.precision_max=v end,
            disabled=function() return addon.db.profile.castbar.focus.text_mode=='simple' end },
        autoAdjust = { type='toggle', order=12, name='Auto Adjust for Auras', desc='Automatically adjust position based on focus auras',
            get=function() return addon.db.profile.castbar.focus.autoAdjust end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','autoAdjust','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.autoAdjust=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        holdTime = { type='range', order=13, name='Hold Time (Success)', desc='Time to show the castbar after successful cast completion', min=0, max=3.0, step=0.1,
            get=function() return addon.db.profile.castbar.focus.holdTime or 0.3 end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','holdTime','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.holdTime=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        holdTimeInterrupt = { type='range', order=14, name='Hold Time (Interrupt)', desc='Time to show the castbar after cast interruption', min=0, max=3.0, step=0.1,
            get=function() return addon.db.profile.castbar.focus.holdTimeInterrupt or 0.8 end,
            set=H and H.createSetFunction and H.createSetFunction('castbar','focus','holdTimeInterrupt','RefreshFocusCastbar') or function(_,v) addon.db.profile.castbar.focus.holdTimeInterrupt=v; if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end end },
        reset_position = { type='execute', order=15, name='Reset Position', desc='Reset focus castbar position to default',
            func=function()
                local defaults = addon.defaults.profile.castbar.focus
                addon.db.profile.castbar.focus.x_position = defaults.x_position
                addon.db.profile.castbar.focus.y_position = defaults.y_position
                if addon.RefreshFocusCastbar then addon.RefreshFocusCastbar() end
            end },
    }}
end

