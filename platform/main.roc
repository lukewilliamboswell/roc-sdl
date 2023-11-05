platform "roc-sdl"
    requires {} { program : _ }
    exposes []
    packages {}
    imports []
    provides [mainForHost]

Program state : { 
    init : { h : I32, w : I32 }, 
} where state implements Decoding & Encoding

mainForHost : Str -> Str
mainForHost = \fromHost ->
    fromHost |> getToHost program 

getToHost : Str, Program state -> Str
getToHost = \fromHost, { init }  ->
    if fromHost |> Str.startsWith "INIT" then 
        "\(Num.toStr init.w)|\(Num.toStr init.h)"
    else 
        "ERROR"
