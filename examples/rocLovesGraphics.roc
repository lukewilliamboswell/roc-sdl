app "example"
    packages {
        pf: "../platform/main.roc",
    }
    imports []
    provides [program] to pf

program = {
    init :  { w : 800, h: 600 },
    render : [
        { x : 0, y : 0, w : 10, h : 600 },
        { x : 0, y : 0, w : 800, h : 10 },
        { x : 790, y : 0, w : 10, h : 600 },
        { x : 0, y : 590, w : 8000, h : 10 },
    ],
}