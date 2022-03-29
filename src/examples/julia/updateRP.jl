using ProgressMeter
using Downloads
using Scratch
using ZipFile

url = "https://github.com/tknopp/RedPitayaDAQServer/releases/download/v0.4.2/red-pitaya-alpine-3.14-armv7-20220216.zip"

function unzip(file; exdir="")
  fileFullPath = isabspath(file) ?  file : joinpath(pwd(),file)
  basePath = dirname(fileFullPath)
  outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(),exdir)))
  isdir(outPath) ? "" : mkdir(outPath)
  zarchive = ZipFile.Reader(fileFullPath)
  for f in zarchive.files
      fullFilePath = joinpath(outPath,f.name)
      if (endswith(f.name,"/") || endswith(f.name,"\\"))
          mkdir(fullFilePath)
      else
          write(fullFilePath, read(f))
      end
  end
  close(zarchive)
end

function downloadImage(url::String, output::String)
  p = Progress(100, 0.5, "Downloading image...")

  function calcDownloadProgress(total::Integer, now::Integer)
    fraction = now/total*100
    fraction = isnan(fraction) ? 0.0 : fraction
    fraction = round(Int64, fraction)
    return fraction+1
  end

  Downloads.download(url, output, progress=(total, now) -> update!(p, calcDownloadProgress(total, now)))
end

function updateRP(host::String, filename::String; user::String="root", password::String="root")
  outputPath = @get_scratch!("rp")
  if isfile(filename)
    filename_ = filename
  else
    output = joinpath(outputPath, "image.zip")
    downloadImage(filename, output)
    filename_ = output
  end

  unzip(filename_, exdir=outputPath)
  packagePath = outputPath*"/"*"apps"*"/"*"RedPitayaDAQServer" # Always use Linux notation

  #run(`expect -c 'spawn ssh $user@$host "rm -r ~/apps/RedPitayaDAQServer"; expect "password:"; send "$password\r"; interact'`)
  #run(`expect -c 'spawn scp $packagePath $user@$host:~/apps; expect "password:"; send "$password\r"; interact'`)
end

updateRP("192.168.1.2", url)