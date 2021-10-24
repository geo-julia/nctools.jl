module nctools

using NCDatasets
using NetCDF
using CFTime
using Dates

include("nc_dim.jl")
include("nc_info.jl")
include("nc_date.jl")
include("nc_read.jl")
include("nc_write.jl")

# CMIP
include("CMIP/CMIP.jl")

export nc_read, nc_write

end # module
