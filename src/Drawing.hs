
module Drawing where

import Components

import qualified Aztecs as Az
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.State.Lazy
import qualified Raylib.Core as RL
import qualified Raylib.Core.Text as RL
import qualified Raylib.Types as RL
import qualified Raylib.Util as RL
import qualified Raylib.Util.Colors as RL

-- | an Access that properly brackets its "drawing" for Raylib.
--   Combine all drawing functions into one and then apply this to it.
drawingAccess :: Az.Access IO a -> Az.Access IO a
drawingAccess acc = Az.Access $ StateT $ \s -> RL.drawing $ runStateT (Az.unAccess acc) s

drawWorld :: Az.Access IO ()
drawWorld = drawBackground >> drawGuy

drawBackground :: MonadIO m => m ()
drawBackground = liftIO $ RL.clearBackground RL.darkGray

drawGuy :: Az.Access IO ()
drawGuy = do
    guyPos's <- Az.system $
        Az.runQueryFiltered (Az.query @IO @Position) (Az.with @IO @Guy)
    forM_ guyPos's $ \ (Position guyPos) -> do
        let x = round $ RL.vector2'x guyPos
            y = round $ RL.vector2'y guyPos
        liftIO $ RL.drawText "Guy" x y 10 RL.magenta
