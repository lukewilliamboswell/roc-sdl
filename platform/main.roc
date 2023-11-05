platform "roc-sdl"
    requires {} { program : _ }
    exposes []
    packages {}
    imports []
    provides [mainForHost]

Program state : { 
    init : { h : I32, w : I32 }, 
    render : List { x : I32, y : I32, h : I32, w : I32 },
} where state implements Decoding & Encoding

mainForHost : Str -> Str
mainForHost = \fromHost ->
    fromHost |> getToHost program 

getToHost : Str, Program state -> Str
getToHost = \fromHost, { init, render }  ->
    if fromHost |> Str.startsWith "INIT" then 
        init |> encodeInit
    else if fromHost |> Str.startsWith "RENDER" then 
        render |> encodeRects
    else 
        "ERROR"

encodeInit : { h : I32, w : I32 } -> Str
encodeInit = \init -> 
    "\(Num.toStr init.w) \(Num.toStr init.h)"
    
encodeRects : List { x : I32, y : I32, h : I32, w : I32 } -> Str
encodeRects = \rects ->
    List.map rects \rect -> "\(Num.toStr rect.x) \(Num.toStr rect.y) \(Num.toStr rect.w) \(Num.toStr rect.h)"
    |> Str.joinWith "|"