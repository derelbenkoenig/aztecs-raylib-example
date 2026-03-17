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
