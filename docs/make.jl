using RedPitayaDAQServer, Documenter

makedocs(
    format = Documenter.HTML(prettyurls = false),
    modules = [RedPitayaDAQServer],
    sitename = "RP DAQ Server",
    authors = "Tobias Knopp, Niklas Hackelberg, Jonas Beuke, Matthias Gräser",
    pages = [
        "Home" => "index.md",
        "Architecture" => "architecture.md",
        "Installation" => "installation.md",
        "Connections" => "connections.md",
        "Cluster" => "cluster.md",
        "Client" => "client.md",
        "Data Acquisition" => "acquisition.md",
        "Signal Generation" => "generation.md",
        "Examples" => Any["Simple" => "examples/simple.md",
                          "Waveforms" => "examples/waveforms.md",
                          "SlowADC" => "examples/slowADC.md"],
        "SCPI Interface" => "scpi.md",
        "FPGA Development" => "fpga.md",
        "Development Tips" => "devtips.md",
        #"Getting Started" => "overview.md",
    ]
#    html_prettyurls = false, #!("local" in ARGS),
)

deploydocs(repo   = "github.com/tknopp/RedPitayaDAQServer.git",
           target = "build")
