url = "https://github.com/tknopp/RedPitayaDAQServer/releases/download/v0.4.2/red-pitaya-alpine-3.14-armv7-20220216.zip"

using ProgressMeter
using Downloads
using Scratch
using GitHub

function downloadImage(url::String)
  p = Progress(100, 0.5, "Downloading image...")
  function calcDownloadProgress(total::Integer, now::Integer)
    fraction = now/total*100
    fraction = isnan(fraction) ? 1.0 : fraction
    fraction = round(Int64, fraction)
    return fraction
  end
  output = joinpath(@get_scratch!("rp"), "image.zip")
  Downloads.download(url, output, progress=(total, now) -> update!(p, calcDownloadProgress(total, now)))
end

rels = releases("tknopp/RedPitayaDAQServer")
@info rels[1][1].assets[1]["browser_download_url"]