{-# LANGUAGE TemplateHaskell #-}

module Lib
    ( someFunc
    ) where

import Components
import Drawing

import qualified Aztecs as Az
import qualified Aztecs.ECS.Query as Az
import qualified Aztecs.ECS.World as AzWorld
import Control.Monad.IO.Class
import Linear
import qualified Raylib.Core as RL
import qualified Raylib.Types as RL
import qualified Raylib.Util as RL

initWorld :: Az.Access IO ()
initWorld = do
    guy <- Az.spawn $ Az.bundle (position 0 0) <> Az.bundle Guy
    pure ()

-- N.B.
--   a System essentially lets you apply modifications to the values of Components
--   but you need an Access if you need the additional power of spawning new entities or
--   deleting existing ones. And while Access is a monad, System is only an Applicative.
--   It's sort of like a free Applicative, which is what enables the ECS to freely rearrange
--   how a System is actually computed more so than if it was a Monad. But liftIO requires
--   MonadIO, which has Monad as a superclass. So because we use liftIO to read keyboard
--   inputs from raylib, the whole thing needs to be an Access rather than a System.
--
--   How could this be avoided? Possibly by reading inputs in a separate step and storing
--   the input buffer somewhere in the World as a component, so this could just be a System
--   that queries the input buffer instead of performing the IO.
--
--   Another idea that springs to mind is to simply define an equivalent of liftIO that does work
--   for System. But if that's even possible, it would be very clearly fighting against the
--   intentional design of Aztecs. The idea that System being Applicative but not a Monad allows
--   more freedom in computing them would go hand in hand with the idea that you can't just do
--   IO in them, wouldn't it!
moveGuy :: Az.Access IO ()
moveGuy = do
    moveDelta <- liftIO $ do
        left <- RL.isKeyDown RL.KeyA
        right <- RL.isKeyDown RL.KeyD
        up <- RL.isKeyDown RL.KeyW
        down <- RL.isKeyDown RL.KeyS
        -- "down" is INCREASING y, apparently
        pure $ V2 (b2f right - b2f left) (b2f down - b2f up)

    Az.system $
        Az.runQueryFiltered (Az.queryMap_ $ updatePos moveDelta) (Az.with @IO @Guy)

    pure ()

    where
        b2f :: Bool -> Float
        b2f = fromIntegral . fromEnum

        updatePos :: RL.Vector2 -> Position -> Position
        updatePos v (Position p) = Position $ p + v

winWidth, winHeight :: Int
winWidth = 1920
winHeight = 1080

winTitle :: String
winTitle = "elf king stuff"

-- setup Raylib app (template haskell)
data AppState = AppState RL.WindowResources (Az.World IO)

rlStartup :: IO AppState
rlStartup = do
    ((), world) <- Az.runAccess initWorld AzWorld.empty
    window <- RL.initWindow winWidth winHeight winTitle
    RL.setExitKey RL.KeyQ
    RL.setTargetFPS 60
    pure $ AppState window world

rlMainLoop :: AppState -> IO AppState
rlMainLoop (AppState window world) = do
    ((), world1) <- Az.runAccess (moveGuy >> drawingAccess drawWorld) world
    pure $ AppState window world1

rlShouldClose :: AppState -> IO Bool
rlShouldClose _ = RL.windowShouldClose

rlTearDown :: AppState -> IO ()
rlTearDown (AppState window world) = RL.closeWindow (Just window)

$(RL.raylibApplication 'rlStartup 'rlMainLoop 'rlShouldClose 'rlTearDown)

someFunc :: IO ()
someFunc = main
