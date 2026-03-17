# aztecs-raylib-example
Getting Aztecs ECS to play with Raylib

## Wiring the app together

See the "setup Raylib app" section in [`src/Lib.hs`](https://github.com/derelbenkoenig/aztecs-raylib-example/blob/main/src/Lib.hs).

Raylib has a `rayLibApplication` function that uses template haskell to generate the
entrypoint of the app. This requires you to give it functions that run in `IO` directly, while
Aztecs lets you define your game loop in its `Access` monad. We need to bridge those two.

For world initialization, you can define an `Access IO ()` that populates the initial entities and
components, and use `runAccess` to execute that as an `IO` action in the `rlStartup` function.

The `rlMainLoop` function has to do more work, unwrapping the `Access` into its underlying
`StateT (World IO)` monad and executing the main game loop on each iteration. The `World IO` state
is then embedded in the `AppState` data that gets returned back to raylib.

## Rendering

Your rendering functions will also likely be written in the `Access` monad, so they can query the
game state for all the components needed for rendering. They will then need to `liftIO` the raylib
functions that they will call to actually draw the things. But, raylib requires you to bracket
your drawing calls with `beginDrawing` and `endDrawing`. This has to do with something called
"double buffering", basically it buffers up your draw instructions then sends them to the GPU all at
once.

For convenience, and possibly more importantly for exception safety, h-raylib provides a function
called `drawing :: IO b -> IO b` that takes your drawing action and automatically does the
`beginDrawing` and `endDrawing` as well as the appropriate exception/signal masking. For
convenience, the `drawingAccess` function does the equivalent for `Access IO ()` by unwrapping the
`Access` and `StateT` constructors and applying `drawing` within the `StateT`.
