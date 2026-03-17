module Components where

import qualified Aztecs as Az
import Linear
import qualified Raylib.Core as RL
import qualified Raylib.Types as RL

newtype Position = Position RL.Vector2
instance Monad m => Az.Component m Position where

position :: Float -> Float -> Position
position x y = Position $ V2 x y

data Guy = Guy
instance Monad m => Az.Component m Guy where

