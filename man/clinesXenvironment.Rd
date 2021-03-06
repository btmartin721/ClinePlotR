% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genomicClinesXenvironment.R
\name{clinesXenvironment}
\alias{clinesXenvironment}
\title{Function to correlate INTROGRESS genomic clines with raster data}
\usage{
clinesXenvironment(
  clineList,
  rasterPointValues,
  rastersToUse = NULL,
  clineLabels = c("P1, Het", "P2"),
  outputDIR = "./plots",
  clineMethod = "permutation",
  prefix = "population1",
  cor.method = "auto"
)
}
\arguments{
\item{clineList}{List object returned from runIntrogress}

\item{rasterPointValues}{List of data.frames with raster values at each
sample locality. See ?extractPointValues}

\item{rastersToUse}{Integer vector indicating which raster layers to use for
genomic cline X environment plots. If NULL, uses all
rasters}

\item{clineLabels}{Character vector of length == 3 designating population
names for c(P1, Het, P2)}

\item{outputDIR}{File path to directory for outputting plots}

\item{clineMethod}{Character string indicating desired method for generating
genomic clines. Must be either "permutation" or
"parametric". See ?introgress}

\item{prefix}{Character prefix for output files}

\item{cor.method}{Method for correlations c("pearson", "kendall", "spearman)}

\item{sample.info}{File path to sample info file with 4 columns:
indID,popID,latitude,longitude}

\item{header}{Boolean specifying if sample.info has a header line}

\item{coords}{data.frame with coordinates. Can be taken from env.list,
an object returned from the prepare_rasters() function.
See ?prepare_rasters(). If used, value is env.list[\link{3}]}
}
\description{
Function to correlate INTROGRESS genomic clines with raster data
}
\examples{
clinesXenvironment(clineList = eatt,
                   rasterPointValues = rasterPoints,
                   rasterToUse = NULL,
                   clineLabels = c("EA", "Het", "TT"),
                   outputDIR = "./cline_plots",
                   clineMethod = "permutation",
                   prefix = "eatt",
                   cor.method = "auto")
}
