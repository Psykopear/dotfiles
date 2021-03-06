{-#LANGUAGE RankNTypes#-}

import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.SetWMName (setWMName)
import XMonad.Hooks.EwmhDesktops (fullscreenEventHook)
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.EZConfig (additionalKeys)
import qualified XMonad.StackSet as W
import System.IO
import Control.Monad
import XMonad.Layout.NoBorders
import XMonad.Hooks.ManageHelpers
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Actions.Search
import XMonad.Actions.Submap
import XMonad.Util.SpawnOnce (spawnOnce)
import qualified XMonad.Util.Brightness as Bright
import XMonad.Actions.Volume
import XMonad.Prompt.Window
import qualified Data.Map as M
import Control.Arrow (first)
import Data.Char (isSpace)
import System.Environment (getArgs)
import Graphics.X11.ExtraTypes.XF86
import Data.Monoid (Endo)

myWorkspaces :: [String]
myWorkspaces = ["main", "web", "chat", "dev", "media", "float", "misc"]

myTerminal :: String
myTerminal = "urxvtc"

-- Notes
-- Mod Key + Q refreshes XMonad session
-- Define the workspace an application has to go to
myManageHook :: XMonad.Query (Endo WindowSet)
myManageHook =
  composeAll . concat $
  [ [isFullscreen --> doFullFloat] -- For Media Players
    -- Applications that go to web
  , [ className =? b --> viewShift "web"
    | b <- myClassWebShifts ]
    -- Applications that go to chat
  , [ resource =? c --> doF (W.shift "chat")
    | c <- myClassChatShifts ]
  , [ resource =? c --> doF (W.shift "dev")
    | c <- myClassDevShifts ]
  , [ resource =? c --> doF (W.shift "media")
    | c <- myClassMediaShifts ]
  , [ resource =? c --> doF (W.shift "float")
    | c <- myClassFloatShifts ]
  , [ resource =? c --> doF (W.shift "misc")
    | c <- myClassMiscShifts ]
  , [ resource =? c --> doF (W.shift "main")
    | c <- myClassMainShifts ]
  ]
  where
    viewShift = doF . liftM2 (.) W.greedyView W.shift
    myClassWebShifts = ["Firefox"]
    myClassChatShifts = ["Pidgin", "eboard", "slack"]
    myClassDevShifts = []
    myClassMediaShifts = ["mplayer", "vlc"]
    myClassFloatShifts = ["gimp", "SMPlayer", "smplayer"]
    myClassMiscShifts = ["nautilus", "seahorse"]
    myClassMainShifts = [".urxvt-wrapped"]

sibiStartupHook :: X ()
sibiStartupHook = do
  as <- io getArgs
  Bright.setBrightness 1260
  setWMName "LG3D"
  when (null as) $
    do spawnOnce "firefox"
       spawnOnce "urxvtd"
       spawnOnce "emacs --daemon"
       spawnOnce "seahorse"

main :: IO ()
main = do
  xmproc <- spawnPipe "xmobar"
  xmonad $
    withUrgencyHook
      NoUrgencyHook
      def
      { manageHook = manageDocks <+> myManageHook <+> manageHook def
      -- No red border for media players
      , terminal = myTerminal
      , startupHook = sibiStartupHook
      , layoutHook = smartBorders $ avoidStruts $ layoutHook def
      , logHook =
        dynamicLogWithPP
          xmobarPP
          { ppOutput = hPutStrLn xmproc
          , ppTitle = xmobarColor "green" "" . shorten 50
          , ppUrgent = xmobarColor "yellow" "red" . xmobarStrip
          }
      , handleEventHook =
        handleEventHook def <+> fullscreenEventHook <+> docksEventHook
      , modMask = mod4Mask -- Rebind Mod to the Windows key
      , workspaces = myWorkspaces
      } `additionalKeys`
    [ ((mod4Mask .|. shiftMask, xK_z), spawn "xscreensaver-command -lock")
    , ((0, xK_Print), spawn "xfce4-screenshooter")
    , ((mod4Mask, xK_x), spawn "xkill")
    , ((mod4Mask, xK_c), kill)
    , ((mod4Mask, xK_p), shellPrompt sibiXPConfig)
    , ((mod4Mask, xK_h), spawn "/home/sibi/.emacs_everywhere/bin/run")
    , ((0, xF86XK_MonBrightnessUp), Bright.increase) 
    , ((0, xF86XK_MonBrightnessDown), Bright.decrease)
    , ((mod4Mask, xK_s), submap $ searchEngineMap $ promptSearch greenSibiXPConfig)
    , ((mod4Mask, xK_f), submap $ searchEngineMap $ selectSearch)
    , ((mod4Mask, xK_g), spawn "unity-control-center")
    , ((0, xF86XK_AudioRaiseVolume), raiseVolume 2 >> return ())
    , ((0, xF86XK_AudioLowerVolume), lowerVolume 2 >> return ())
    , ((0, xF86XK_AudioMute), toggleMute >> return ())
    , ((mod4Mask, xK_b), windowPromptBring sibiXPConfig)
    , ((mod4Mask, xK_g), windowPromptGoto sibiXPConfig)
    ]

sibiXPConfig :: XPConfig
sibiXPConfig =
  def
  { alwaysHighlight = True
  , promptKeymap = sibiEmacsKeymap
  , position = Top
  , font = "xft:Ubuntu Mono:size=12:bold:antialias=true"
  , completionKey = (controlMask, xK_i)
  }

greenSibiXPConfig :: XPConfig
greenSibiXPConfig =
  sibiXPConfig
  { alwaysHighlight = False
  , fgColor = "green"
  , bgColor = "black"
  , promptBorderWidth = 0
  }

sibiEmacsKeymap :: M.Map (KeyMask, KeySym) (XP ())
sibiEmacsKeymap = sibiEmacsKeymap' isSpace

-- Modified from source to suit my key binding
sibiEmacsKeymap' :: (Char -> Bool) -> M.Map (KeyMask, KeySym) (XP ())
sibiEmacsKeymap' p =
  M.fromList $
  map
    (first $ (,) controlMask)
    [ (xK_z, killBefore) --kill line backwards
    , (xK_k, killAfter) -- kill line fowards
    , (xK_a, startOfLine) --move to the beginning of the line
    , (xK_e, endOfLine) -- move to the end of the line
    , (xK_d, deleteString Next) -- delete a character foward
    , (xK_b, moveCursor Prev) -- move cursor forward
    , (xK_f, moveCursor Next) -- move cursor backward
    , (xK_BackSpace, killWord' p Prev) -- kill the previous word
    , (xK_y, pasteString)
    , (xK_g, quit)
    , (xK_bracketleft, quit)
    , (xK_h, deleteString Prev)
    , (xK_j, setSuccess True >> setDone True)
    ] ++
  map
    (first $ (,) mod1Mask)
    [ (xK_BackSpace, killWord' p Prev)
    , (xK_f, moveWord' p Next) -- move a word forward
    , (xK_b, moveWord' p Prev) -- move a word backward
    , (xK_d, killWord' p Next) -- kill the next word
    , (xK_n, moveHistory W.focusUp')
    , (xK_p, moveHistory W.focusDown')
    ] ++
  map
    (first $ (,) 0)
    [ (xK_Return, setSuccess True >> setDone True)
    , (xK_KP_Enter, setSuccess True >> setDone True)
    , (xK_Delete, deleteString Next)
    , (xK_Left, moveCursor Prev)
    , (xK_Right, moveCursor Next)
    , (xK_Home, startOfLine)
    , (xK_End, endOfLine)
    , (xK_Down, moveHistory W.focusUp')
    , (xK_Up, moveHistory W.focusDown')
    , (xK_Escape, quit)
    , (xK_BackSpace, deleteString Prev)
    ]


searchEngineMap :: forall a b.(Ord a, Num a) => (SearchEngine -> b) -> M.Map (a, KeySym) b
searchEngineMap method =
  M.fromList $
  [ ((0, xK_g), method google)
  , ((0, xK_h), method stackage)
  , ((0, xK_w), method wikipedia)
  , ((0, xK_v), method vocabulary) -- main = do
  ]
--   xmonad $ defaultConfig
-- Reference
-- https://wiki.haskell.org/Xmonad/Frequently_asked_questions#I_need_to_find_the_class_title_or_some_other_X_property_of_my_program
