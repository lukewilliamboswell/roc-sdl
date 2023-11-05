platform "roc-sdl"
    requires {} { main : _ }
    exposes []
    packages {}
    imports []
    provides [mainForHost]

mainForHost : Str -> Str
mainForHost = main