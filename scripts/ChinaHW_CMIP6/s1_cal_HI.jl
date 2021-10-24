using nctools
# using RCall

# pan = "/media/kong/GitHub"
# pan = "/mnt/k"
pan = "K:"
dir_prj  = "$pan/Researches/CMIP6/ChinaHW_cluster"
dir_data = "$pan/Researches/CMIP6/CMIP6_ChinaHW_mergedFiles"


dirs = dir(dir_data)
files = dir(dirs[1], "nc", recursive = true)
CMIPFiles_info(files)

## R PART ----------------------------------------------------------------------
R"""
# devtools::load_all($dir_prj)
library(CMIP6tools)
dir_data = $dir_data
dirs <- dir(dir_data, "^hu|^tas", full.names = TRUE) %>% set_names(basename(.))

lst <- foreach(indir = dirs, i = icount()) %do% {
    files <- dir(indir, "*.nc", recursive = TRUE, full.names = TRUE)
    CMIP5Files_info(files)
}
d_RH <- lst$hurs

overwrite <- FALSE
varnames <- c("tasmin", "tasmax") %>% set_names(., .)
# varname = varnames[2]
# temp <- foreach(varname = varnames) %do% {
get_fileInfo <- function(varname = "tasmax"){
    d_tair <- lst[[varname]]
    l <- list(d_RH, d_tair) %>%
        map(~ .[, .(model, ensemble, start, end, file)])
    d <- c(l, list(suffixes = c(".rh", ".tair"), by = c("model", "ensemble"))) %>%
        do.call(merge, .)

    varname.new <- paste0("HI", varname)
    filename <- basename(d$file.rh) %>% gsub("hurs", varname.new, .)
    d$outfile <- glue("{dir_data}/{varname.new}/{filename}")
    d
}
"""

## Julia PART ------------------------------------------------------------------
d = R"get_fileInfo('tasmax')" |> rcopy

nrow = length(d[:, 1])
for i = 1:nrow
    println("[$i]: $(d.model[i])")
    outfile = d.outfile[i]
    # outfile = "HI_check.nc"
    CMIP6_heat_index(d.file_tair[i], d.file_rh[i], outfile; raw = true, compress = 1, overwrite = false)
end
