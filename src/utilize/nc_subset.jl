"""
    $(TYPEDSIGNATURES)

# Arguments

- `check_vals`: If download failed, `length(unique(vals)) = 1`. Default check
  the length of data unique values


# Example

```julia
url = "http://esgf-data04.diasjp.net/thredds/dodsC/esg_dataroot/CMIP6/CMIP/CSIRO-ARCCSS/ACCESS-CM2/historical/r1i1p1f1/day/huss/gn/v20191108/huss_day_ACCESS-CM2_historical_r1i1p1f1_gn_18500101-18991231.nc"

range = [70, 140, 15, 55]
delta = 5

@time nc_subset(url, range)
```

$(METHODLIST)
"""
function nc_subset(f, range::Vector, fout=nothing; 
    delta=5, 
    check_vals=true, verbose=true,
    big=false,
    outdir=".", overwrite=false)

  fout === nothing && (fout = "$outdir/$(basename(f))")
  if isfile(fout) && !overwrite
    verbose && println("[ok] file downloaded already!")
    return
  end

  nc = nc_open(f)
  printstyled("Reading dims...\n")
  # @time dims = ncvar_dim(nc)
  @time dims = ncvar_dim(nc)
  band = nc_bands(nc)[1] # 只选择其中一个变量

  lonr = range[1:2] + [-1, 1] * delta# longitude range
  latr = range[3:4] + [-1, 1] * delta# latitude range
  v = @select(nc[band], $lonr[1] <= lon <= $lonr[2] && $latr[1] <= lat <= $latr[2])

  (ilon, ilat, _) = parentindices(v)
  
  dims[1] = dims["lon"][ilon]
  dims[2] = dims["lat"][ilat]
  printstyled("Reading data...\n")

  ntime = dims[end].dimlen
  ndim = ndims(v)
  
  if big
    lst = split_chunk(ntime, 6)
    tmp = map(itime -> begin
      println("\t[chunk]: $itime")
      _inds = tuple(inds[1:3]..., 1)
      v.var[_inds]
    end, lst)
    vals = cat(tmp...; dims = ndim)
  else
    inds = ntuple(i -> :, ndims(v))
    @time vals = v.var[inds...]
  end
  
  if check_vals && length(unique(vals)) == 1
    printstyled("[error] downloaded file failed: $f \n", color=:red)
    return
  end
  
  printstyled("Writing data...\n")
  @time nc_write(fout, band, vals, dims, Dict(v.attrib); 
    compress=1, goal_attrib=Dict(nc.attrib))
  # ncatt_put(fout, Dict(nc.attrib))
end


function nc_subset(d::AbstractDataFrame, range; 
    outdir=".", kw...)

  prefix = str_extract(basename(d.file[1]), ".*(?=_\\d{4})")
  date_begin = d.date_begin[1]
  date_end = d.date_end[end]

  fout = "$outdir/$(prefix)_$date_begin-$date_end.nc"
  urls = collect(d.file)
  nc_subset(urls, range, fout; kw...)
end


export nc_subset
