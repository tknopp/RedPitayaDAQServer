using RedPitayaDAQServer, Documenter

makedocs(
    format = :html,
    modules = [RedPitayaDAQServer],
    sitename = "RP DAQ Server",
    authors = "Tobias Knopp, Jonas Beuke, Matthias Gräser",
    pages = [
        "Home" => "index.md",
        "Installation" => "installation.md"
        #"Getting Started" => "overview.md",
    ],
    html_prettyurls = false, #!("local" in ARGS),
)

deploydocs(repo   = "github.com/tknopp/RedPitayaDAQServer.jl.git",
           target = "build")
