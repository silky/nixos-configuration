-- XMonad config.
-- This is a simple config with a focus on being able to switch between
-- layouts easily.
--
-- Author: Noon van der Silk
-- Location: http://github.com/silky/nixos-configuration
--
-- Inspiration:
--  http://www.haskell.org/haskellwiki/Xmonad/Config_archive/Brent_Yorgey%27s_Config.hs
--  http://www.haskell.org/wikiupload/9/9c/NNoeLLs_Desktop_2011-08-31.png
--  http://xmonad.org/xmonad-docs/xmonad/src/XMonad-Config.html
--  https://bitbucket.org/tobyodavies/shared/src
--  https://betweentwocommits.com/blog/xmonad-layouts-guide
--  https://github.com/Axarva/dotfiles-2.0/blob/main/xmonad/xmonad.hs

-- https://github.com/kmarzic/dotfiles/blob/master/.xmonad/xmonad.ansi.hs

import Data.List.Split (splitOn)
import Data.Maybe (isJust)
import System.IO
import Control.Monad.Trans.Maybe (MaybeT)
import XMonad hiding ( (|||) )
import XMonad.Actions.CopyWindow
import XMonad.Actions.CycleWS
import XMonad.Actions.UpdatePointer
import XMonad.Actions.WindowBringer
import XMonad.Actions.WindowGo
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeWindows
import XMonad.Hooks.Place
import XMonad.Hooks.SetWMName
import XMonad.Layout.Circle
import XMonad.Layout.Fullscreen
import XMonad.Layout.Grid
import XMonad.Layout.Groups.Examples
import XMonad.Layout.LayoutCombinators
import XMonad.Layout.LayoutHints
import XMonad.Layout.MultiColumns
import XMonad.Layout.ResizableTile
import XMonad.Layout.Named (named)
import XMonad.Layout.NoBorders
import XMonad.Layout.OneBig
import XMonad.Layout.Spiral
import XMonad.Layout.ToggleLayouts
import XMonad.Layout.ZoomRow
import XMonad.Util.EZConfig
import XMonad.Util.Run (spawnPipe)
import XMonad.Hooks.ManageDocks
import XMonad.Layout.IndependentScreens

import qualified XMonad.StackSet as W
import qualified Data.Map        as M


myLayout = layoutHints $ smartBorders $
        named "Tiled"          tiled
    ||| named "MTiled"         (Mirror tiled)
    ||| named "CenteredMaster" (zoomRow)
    ||| noBorders Full
    ||| named "TallCols"       (Mirror $ multiCol [1] nmaster delta (1/2))
    ||| named "Circle"         Circle
    ||| named "Big"            (OneBig (3/4) (3/4))
    ||| named "Resizable"      (ResizableTall nmaster delta (1/2) [])
  where
     tiled   = Tall nmaster delta ratio

     -- The default number of windows in the master pane
     nmaster = 1

     -- Default proportion of screen occupied by master pane
     ratio   = (2/(1 + (toRational (sqrt 5 :: Double))))

     -- Percent of screen to increment by when resizing panes
     delta   = 1/100


layoutChangeModMask = mod1Mask .|. shiftMask


myKeys conf =
  [ ((layoutChangeModMask, xK_f), sendMessage $ JumpToLayout "Full")
  , ((layoutChangeModMask, xK_t), sendMessage $ JumpToLayout "Tiled")
  -- , ((layoutChangeModMask, xK_w), sendMessage $ JumpToLayout "MTiled")
  , ((layoutChangeModMask, xK_b), sendMessage $ JumpToLayout "Big")
  , ((layoutChangeModMask, xK_p), sendMessage $ JumpToLayout "Resizable")
  --
  -- Expand sub-sections in Resizable-Tall
  , ((mod1Mask, xK_a), sendMessage MirrorShrink)
  , ((mod1Mask, xK_z), sendMessage MirrorExpand)

  -- Stop Alt-Shift-Q logging out
  , ((layoutChangeModMask, xK_q), pure () )
  --
  -- Brightness: Alt-Shift +/-
  , ((layoutChangeModMask, xK_equal), spawn "brightnessctl s '2%+'")
  , ((layoutChangeModMask, xK_minus), spawn "brightnessctl s '2%-'")
  --
  -- Launch specific things
  , ((mod1Mask, xK_o), spawn "nautilus --no-desktop")
  , ((mod1Mask, xK_m), spawn "alacritty -e alsamixer")
  , ((mod1Mask, xK_e), spawn "alacritty -e nvim")
  , ((mod1Mask, xK_d), spawn "alacritty -e nvim -c ':Daily'")
  , ((mod1Mask, xK_p), spawn "dmenu_run -nb '#d1f0ff' -sf '#b141e5' -nf '#333333' -sb '#d1f0ff'")
  , ((mod1Mask, xK_b), spawn "show-battery-state")

  -- Monitors
  , ((mod1Mask, xK_n), spawn "mobile") -- "(N)o work"
  , ((mod1Mask, xK_w), spawn "work")   -- "(W)ork"
  --
  --
  -- Move mouse focus to the other screen; useful for more a setup with more
  -- than one screen
  , ((mod1Mask, xK_q), screenWorkspace 0 >>= flip whenJust (windows . W.view))
  , ((mod1Mask, xK_r), screenWorkspace 1 >>= flip whenJust (windows . W.view))
  --
  , ((mod1Mask, xK_s), spawn "flameshot gui")
  --
  , ((layoutChangeModMask, xK_s), swapScreen)
  --
  , ((mod1Mask, xK_g), bringMenu) -- "Grab"
  ]
  -- Normal-mode open screens
  ++
  [ ((mod1Mask .|. e, k), windows $ onCurrentScreen f i)
      | (i, k) <- zip myWorkspaces [ xK_0, xK_1 .. xK_9 ]
      , (f, e) <- [(W.greedyView, 0), (W.shift, shiftMask)]
  ]
  -- Alt-mode open screens
  -- ++
  -- [ ((mod1Mask .|.  controlMask .|. e, k), altSwitchScreen 2 f i)
  --     | (i, k) <- zip (workspaces' conf) [xK_1 .. xK_9]
  --     , (f, e) <- [(W.greedyView, 0), (W.shift, shiftMask)]
  -- ]

-- TODO: Make the clicky-toggley-thing rotate around these screens as well.
-- TODO: The below is too slow. Need to only change the bg once.

-- altSwitchScreen i f vws = do
  -- currentScreenId <- (+i) <$> currentScreen
  -- let cmd = if currentScreenId >= 2
  --           then "feh --bg-fill ~/Pictures/bgs/work.jpg"
  --           else "feh --bg-fill ~/Pictures/bgs/normal.jpg"
  -- spawn cmd
  -- windows $ f (marshall currentScreenId vws)


-- https://stackoverflow.com/questions/33547168/xmonad-combine-dwm-style-workspaces-per-physical-screen-with-cycling-function
swapScreen =  do
  x <- currentScreen
  y <- gets (W.tag . W.workspace . W.current . windowset)

  -- TODO: Could use unmarshall/marshall
  -- HACK: Relies on details of `XMonad.Layout.IndependentScreens` ...
  let [left,right] = splitOn "_" y
      toggle "0"   = "1"
      toggle "1"   = "0"
      toggle _     = error "Un-toggleable!"

  windows $ W.shift (toggle left ++ "_" ++ right)


-- Toggle the active workspace with the 'Forward/Back' mouse buttons.
myMouseMod = 0
myMouseBindings x = M.fromList $
    [ ((myMouseMod, 8), const $ moveTo Prev nonEmptySpacesOnCurrentScreen)
    , ((myMouseMod, 9), const $ moveTo Next nonEmptySpacesOnCurrentScreen)
    ]


isOnScreen :: ScreenId -> WindowSpace -> Bool
isOnScreen s ws = s == unmarshallS (W.tag ws)


currentScreen :: X ScreenId
currentScreen = gets (W.screen . W.current . windowset)


-- TODO: Could make this shift to the secondary layer with shift, or
-- something.
nonEmptySpacesOnCurrentScreen :: WSType
nonEmptySpacesOnCurrentScreen = WSIs $ do
  s <- currentScreen
  return $ \x ->
    isJust (W.stack x)
    && isOnScreen s x
    && (unmarshallW (W.tag x) /= "0") -- Skip the "scratch" workspaces


myWorkspaces :: [WorkspaceId]
myWorkspaces = map show [ 0, 1 .. 9 :: Int ]


main :: IO ()
main = do
  nScreens <- countScreens
  -- Double the number of screens as we're going to have a "second space",
  -- where work things will live.
  -- nScreens <- fmap (*2) countScreens
  let myConfig = ewmh def {
          borderWidth        = 1
        , workspaces         = withScreens nScreens myWorkspaces
        , terminal           = "alacritty"
        , normalBorderColor  = "#000000"
        , focusedBorderColor = "#b141f2"
        , layoutHook         = avoidStruts myLayout
        , mouseBindings      = myMouseBindings
        , modMask            = mod1Mask
        -- Update pointer to be in the center on focus; I tried
        -- it being the 'Nearest' option, but this was not good
        -- because it still contains the bug wherein you shift
        -- to a new window and focus doesn't change.
        --
        -- Note: This breaks in GIMP for various reasons that I
        -- don't care to investigate right now. If you have troubles
        -- there, just comment it out (or fix it and tell me!).
        , logHook            = updatePointer (0.5, 0.5) (0, 0)
      } `additionalKeys'` myKeys

  xmonad $ docks myConfig


additionalKeys' :: XConfig a -> (XConfig a -> [((KeyMask, KeySym), X ())]) -> XConfig a
additionalKeys' conf keyList =
    conf { keys = \cnf -> M.union (M.fromList (keyList conf)) (keys conf cnf) }
