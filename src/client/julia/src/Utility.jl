# https://discourse.julialang.org/t/how-to-extract-a-file-in-a-zip-archive-without-using-os-specific-tools/34585/5
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

  return outPath
end

function downloadImage(url::URI; force=false)
  p = Progress(1000, 0.5, "Downloading image...")
  function calcDownloadProgress(total::Integer, now::Integer)
    fraction = now/total*1000
    fraction = isnan(fraction) ? 1.0 : fraction
    fraction = round(Int64, fraction)
    return fraction
  end
  splittedUrl = URIs.splitpath(url)
  fileName = splittedUrl[end]
  tagName = splittedUrl[end-1]
  scratch = @get_scratch!("releases")
  releaseFolder = mkpath(joinpath(scratch, tagName))
  output = joinpath(releaseFolder, fileName)

  if !isfile(output) || force
    Downloads.download(string(url), output, progress=(total, now) -> ProgressMeter.update!(p, calcDownloadProgress(total, now)))
  else
    @debug "The image at `$url` does already exist and was thus not downloaded. Use `force=true` to download it anyways."
  end

  return output
end
downloadImage(tagName::String; kwargs...) = downloadImage(getImageURL(tagName); kwargs...)

function getImageURL(tagName::String)
  rels = releases("tknopp/RedPitayaDAQServer")[1]
  relIdx = findfirst([rel.tag_name for rel in rels] .== tagName)
  if !isnothing(relIdx)
    rel = rels[relIdx]
    assets = rel.assets
    if length(assets) > 0
      asset = assets[1] # Assumes only one asset and this should be the image
      url = asset["browser_download_url"]

      if endswith(url, ".zip")
        return URI(url)
      else
        error("The asset of the release with tag `$tagName` is not a .zip file.")
      end
    else
      error("No assets were found for the release with tag `$tagName`.")
    end
  else
    error("No matching release for tag `$tagName` was found.")
  end
end

export listReleaseTags
"""
    listReleaseTags()

Return a vector of release tags
"""
function listReleaseTags()
  rels = releases("tknopp/RedPitayaDAQServer")[1]
  return [rel.tag_name for rel in rels]
end

"""
    latestReleaseTag()

Return the latest release tag.

See also [`listReleaseTags`](@ref), [`update!`](@ref).

# Examples
```julia
julia> update!("192.168.1.100", latestReleaseTag())
...
```
"""
export latestReleaseTag
function latestReleaseTag()
  return listReleaseTags()[1]
end

function downloadAndExtractImage(tagName::String; force=false)
  imageZipPath = downloadImage(tagName, force=force)
  imagePath = joinpath(dirname(imageZipPath), "extracted")

  if isdir(imagePath)
    if force
      rm(imagePath, recursive=true, force=true)
      return unzip(imageZipPath, exdir=imagePath)
    else
      @debug "The image with tag `$tagName` was already extracted and is thus not being extracted again. Use `force=true` to extract it anyways."
      return imagePath
    end
  else
    return unzip(imageZipPath, exdir=imagePath)
  end
end

extractedImagePath(tagName::String) = joinpath(@get_scratch!("rp"), tagName, "extracted")

export uploadBitfile
function uploadBitfile(ip::String, bitfilePath::String)
  imagePath = extractedImagePath(tagName)
  keyPath = joinpath(imagePath, "apps", "RedPitayaDAQServer", "rootkey")
  argument = Cmd(["-i", keyPath, bitfile, "root@$(ip):/media/mmcblk0p1/apps/RedPitayaDAQServer/bitfiles"])
  run(`$(scp()) $argument`)
end

function uploadBitfiles(ip::String, tagName::String)
  imagePath = extractedImagePath(tagName)
  bitfilePath = joinpath(imagePath, "apps", "RedPitayaDAQServer", "bitfiles")
  bitfiles = [joinpath(bitfilePath, bitfile) for bitfile in readdir(bitfilePath)]
  
  for bitfile in bitfiles
    uploadBitfile(ip, bitfile)
  end
end

export update!
"""
Update the Red Pitaya with the release from the given tag.
"""
function update!(ip::String, tagName::String)
  if Sys.iswindows()
    success(`where ssh`) || error("'ssh' not found.")
    success(`where scp`) || error("'scp' not found.")
    success(`where git`) || error("'git' not found.")
  else
    success(`which ssh`) || error("'ssh' not found.")
    success(`which scp`) || error("'scp' not found.")
    success(`which git`) || error("'git' not found.")
  end

  @info "Downloading tagged release"
  imagePath = downloadAndExtractImage(tagName)
  projectPath = joinpath(imagePath, "apps", "RedPitayaDAQServer")
  keyPath = joinpath(projectPath, "rootkey")

  # Prepare folder for RPs without internet connection
  @info "Preparing RedPitayaDAQServer folder"
  argument = Cmd(["config", "--add", "safe.directory", projectPath])
  run(setenv(`git $argument`, dir=projectPath))
  argument = Cmd(["config", "--add", "safe.directory", joinpath(projectPath, "libs", "scpi-parser")])
  run(setenv(`git $argument`, dir=projectPath))
  argument = Cmd(["submodule", "update", "--init", "--force", "--remote"])
  run(setenv(`git $argument`, dir=projectPath))
  chmod(keyPath, 0o400) # Otherwise private key is not accepted by ssh as it is unsecure

  @info "Uploading folder"
  # Remove old folder
  argument = Cmd(["-i", keyPath, "root@$(ip)", "rm -r /media/mmcblk0p1/apps/RedPitayaDAQServer"])
  run(`ssh $argument`)

  # Create new folder
  argument = Cmd(["-i", keyPath, "root@$(ip)", "mkdir /media/mmcblk0p1/apps/RedPitayaDAQServer"])
  run(`ssh $argument`)

  # Upload new folder
  argument = Cmd(["-i", keyPath, "-rp", "$projectPath/", "root@$(ip):/media/mmcblk0p1/apps"])
  run(`scp $argument`)

  @info "Preparing server"
  # Run make on RP, since we do not necessarily have all set-up to do a cross-compile
  argument = Cmd(["-i", keyPath, "root@$(ip)", "cd /media/mmcblk0p1/apps/RedPitayaDAQServer && make server"])
  run(`ssh $argument`)
  @info "Successfully updated RedPitaya $ip"
end
update!(rp::RedPitaya, tagName::String) = update!(rp.host, tagName::String)
update!(rpc::RedPitayaCluster) = [update!(rp) for rp in rpc]
