app "example"
    packages {
        pf: "../platform/main.roc",
    }
    imports []
    provides [program] to pf


# program : 
program = {
    init :  { w : 800, h: 600 },
}