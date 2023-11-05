app "example"
    packages {
        pf: "../platform/main.roc",
    }
    imports []
    provides [main] to pf

main = \_ -> "Hello World!"