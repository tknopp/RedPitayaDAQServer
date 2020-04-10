using RedPitayaDAQServer, Documenter

makedocs(
    format = Documenter.HTML(prettyurls = false),
    modules = [RedPitayaDAQServer],
    sitename = "RP DAQ Server",
    authors = "Tobias Knopp, Jonas Beuke, Matthias Gräser",
    pages = [
        "Home" => "index.md",
        "Installation" => "installation.md",
        "Architecture" => "architecture.md",
        "Cluster" => "cluster.md",
        "Client" => "client.md",
        "Examples" => Any["Simple" => "examples/simple.md",
                          "SlowADC" => "examples/slowADC.md"],
        "SCPI Interface" => "scpi.md",
        "FPGA Development" => "fpga.md",
        #"Getting Started" => "overview.md",
    ]
#    html_prettyurls = false, #!("local" in ARGS),
)

deploydocs(repo   = "github.com/tknopp/RedPitayaDAQServer.jl.git",
           target = "build")
