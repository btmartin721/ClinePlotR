# ClinePlotR
Plot BGC and INTROGRESS genomic cline results and correlate INTROGRESS clines with environmental variables.

ClinePlotR allows you to plot BGC (Bayesian Genomic Cline) output. After we ran BGC, we realized it wasn't easy to plot the BGC results, so we put together this package in the process of figuring it out.

The package allows you to make several plots.

## Dependencies

ClinePlotR has several dependencies. 

The bgcPlotter functions require:

* data.table
* dplyr
* bayestestR
* scales
* reshape2
* ggplot2
* forcats
* gtools
* RIdeogram
* gdata
* adegenet

The environmental functions require:

* ENMeval
* rJava
* raster
* sp
* dismo

The INTROGRESS functions require:  
* introgress
* ggplot2
* dplyr
* scales

## Installing the Package

To install ClinePlotR, you can do the following:

```
# If you don't already have devtools installed
install.packages("devtools")

devtools::install_github("btmartin721/ClinePlotR")
``` 

Now load the library.  
```
library("ClinePlotR")
```

## bgcPlotR

The BGC functions allow you to:  
1. Plot genomic clines as Phi (Prob. P1 ancestry) on the Y-axis and hybrid index on the X-axis.  
2. Plot a chromosomal ideogram with BGC outliers shown on chromosomes.    




### Phi ~ Hybrid Index Plots  

First, the Phi plot that Gompert et al. made in some of their papers. In this plot, Phi is the Probability of P1 ancestry, and the Probability of P0 ancestry is 1 - Phi. Phi is plotted on the Y-axis and hybrid index on the X-axis.  

Here is an example of a Phi plot that ClinePlotR can make:  

<img src="vignettes/eatt_genes_hiXphi_alphaAndBeta.png" width="60%">  

In the above plot, significant BGC alpha outlier clines are highlighted in black, and the non-significant loci are gray. A hybrid index histogram is included above the Phi plot. A separate plot is automatically made to highlight beta outliers. Many aspects of the plot can be adjusted with arguments to suit your needs, including colors, width/height, margins, criteria for determining outliers, and many more.  

With BGC, positive alpha outliers indicate excess P1 ancestry compared to the genome-wide average. Negative indicate excess P0 ancestry.  

Positive beta outliers indicate a steeper cline (i.e. a faster rate of transition and selection against introgression), whereas negative beta indicates hybrid vigor (i.e. higher introgression than expected).  

### Chromosome Plots  

If you have appropriate data and follow some steps beforehand, our package will also let you plot the alpha and beta outliers on a karyotype, like here:  

<img src="vignettes/ideogram_EATT.png">  

For each chromosome, alpha outliers are plotted on the left and beta are on the right. The larger bands represent outliers that fell in known mRNA loci, whereas the thinner bands are from unknown scaffolds. This way, you can visualize the outliers on actual chromosomes.  

Here few things you need to have to make the ideogram:  

* You need to run BGC twice
  + Once with transcriptome-aligned SNPs
  + Another time with all unlinked SNPs with unplaced scaffolds.  

* You need an appropriately close reference genome   
  + Fully assembled at the chromosome level  

* You need a reference transcriptome  
* At least scaffold-level assembly for your study species  
* A GFF file  
* The transcript and scaffold IDs have to line up with the BGC loci  

If you don't have all those things, you can still make the Phi plots.   

You should have the following files to run this package:  

### Necessary Phi Input Files

* Loci File

This file is a two-column whitespace-separated file with locus ID as column 1 and SNP position as column 2.  

Here is an example what this should look like: 

```
#CHROM POS
XM_024192520.2 851
XM_024192520.2 854
XM_024192520.2 859
```

Each line is one locus.  

The first column indicates transcript or scaffold ID. The second indicates the SNP position on the scaffold or mRNA.   

If you don't want to make the ideogram, these values can be made up.  

* BGC Output Files  

  + prefix_bgc_stat_a0_runNumber
  + prefix_bgc_stat_b0_runNumber
  + prefix_bgc_stat_qa_runNumber
  + prefix_bgc_stat_qb_runNumber
  + prefix_bgc_stat_hi_runNumber
  + prefix_bgc_stat_LnL_runNumber
  
E.g., population1_bgc_stat_a0_1  

These suffixes are required for the input files.  

The bgc_stat files can be generated with the estpost software included with BGC. estpost can create these files from the HDF5 file that BGC writes to.  

The qa and qb files are generated by using the gamma-quantile and zeta-quantile options with the -p parameter.  

When using estpost, don't include header lines, and output them to ascii format.  

I.e., use the following options:  

```-s 2 -w 0```  

This will format them correctly for ClinePlotR.  


* Population Map File

It should be a two-column, tab-separated file with individual IDs as column 1 and population ID as column 2. No header.

E.g., 

```
ind1 population1
ind2 population1
ind3 population2
ind4 population2
```


### Make Phi Plots

#### Aggregate BGC Runs

If you ran multiple BGC runs, ClinePlotR allows you to aggregate them together to increase your MCMC sampling. Log-likelihood MCMC traces can be made with the plot_lnl() function to assess convergence. This is **strongly** recommended if aggregating BGC runs. You should make sure all five runs have converged (see the LnL traces below).

To aggregate the BGC runs, you first need the BGC output in the correct format.

First, you need to run combine_bgc_output()

```
bgc.genes <-
  combine_bgc_output(results.dir = "exampledata/genes/",
                     prefix = "population1)
```  

This is with the default options.  

If you determine that you want to thin the MCMC samples, you can use the thin parameter:

```
bgc.genes <-
  combine_bgc_output(results.dir = "exampledata/",
                     prefix = "population1", 
                     thin = 2)
```

This will thin it to every 2nd sample. Keep in mind that this is thinning the MCMC **samples**, not all the iterations. So if you had a total of 200,000 post-burnin iterations X 5 runs (i.e. 1,000,000 total iterations), and you told BGC to sample every 40 generations, you would end up with 5000 X 5 = 25,000 MCMC samples.

If you then used combine_bgc_output to thin every 2nd iteration, it would retain 12,500 MCMC samples.

One reason to use this is if you have a ton of loci and you want to reduce the computational burden.

Another available option is to discard the first N MCMC samples.

```
bgc.genes <-
  combine_bgc_output(results.dir = "exampledata/",
                     prefix = "population1",
                     discard = 2500)
```

This will discard the first 2500 samples from **each run**. So if like in the example before you had 25,000 MCMC samples, and you discarded 2500, you would end up with 12,500 MCMC samples. The difference here is that instead of taking every Nth sample, you are taking the last N samples of each run.

One reason to use this is if you notice that the runs converged e.g. 2500 samples post-burnin. In this case you could just discard the non-converged portions of the runs.

#### Plot BGC Parameter Traces

It is **strongly** recommended to inspect the traces if you are aggregating the runs. You can do this with the plot_traces() function.

```
plot_traces(df.list = bgc.genes,
         prefix = "population1",
         plotDIR = "./plots")
```

This function uses the object created with combine_bgc_output().

The plot will be saved in plotDIR.

Here are some examples that plot_traces() makes:

<img src="vignettes/LnL_convergence.png" width="50%">  

<img src="vignettes/alphaTrace.png" width="50%">


Here we aggregated five BGC runs with 2,000 samples each. You can see that all five converged.

Here's an example of LnL that didn't converge among the five runs:

![LnL Plot: Didn't Converge.](vignettes/bad_LnL_convergence.png)

You can tell the five runs started to converge towards the end, but the LnL were still rising until close to the end of the run. This one needed to be re-run with longer burn-in.

#### Identify Outlier Loci

Here we identify alpha and beta outliers using the get_bgc_outliers() function.

For this you need a population map file (see above).

```
gene.outliers <-
  get_bgc_outliers(
    df.list = bgc.genes,
    admix.pop = "population1",
    popmap = "exampledata/popmap.txt",
    loci.file = "exampledata/genes/population1_bgc_loci.txt",
    qn = 0.975)
```

get_bgc_outliers records outliers in three ways.

1. If the credible interval for alpha or beta do not overlap zero.

2. If alpha or beta falls outside the quantile interval: qn / 2 and (1 - qn) / 2. This one is more conservative.

3. If both are TRUE. This is the most conservative one.

qn can be adjusted. The default is 0.975 as the upper interval bound. If you set the qn parameter to 0.95, the interval will be 0.95 / 2 and (1 - 0.95) / 2.

The object returned from this can be input directly into phiPlot(). 

You can save this function's output as an RDS object for later use by setting save.obj = TRUE

#### Plot Genomic Clines

Now you can make the Phi genomic cline plot. The popname can be any string you want here.

```
phiPlot(outlier.list = gene.outliers,
        popname = paste0("Pop 1", " Genes"),
        line.size = 0.25,
        saveToFile = paste0(prefix, "_genes"),
        plotDIR = "./plots/",
        hist.y.origin = 1.2,
        hist.height = 1.8,
        margins = c(160.0, 5.5, 5.5, 5.5),
        hist.binwidth = 0.05)
```

If you want to save the plot to a file, just use the saveToFile option. If specified, it should be the filename you want to save to. If you don't use this option, it will appear in your Rstudio plot window.

Most of the plot settings can be adjusted. See ?phiPlot for more info.

You can change the criteria for identifying outlier loci with the overlap.zero, qn.interval, and both.outlier.tests options. By default, it is set to identify outliers using either overlap.zero or qn.interval. I.e. it only has to meet at least one of the criteria. You can turn one or the other off if you want by setting e.g. overlap.zero = FALSE. They can't both be off unless both.outlier.tests = TRUE.

If you set both.outlier.tests to TRUE, it will require that outliers meet both criteria. This overrides overlap.zero and qn.interval settings.

E.g.,

![Phi Plot: Both Outlier Tests.](vignettes/population1_both.outlier.tests.png)

This is a more conservative outlier test. There will be fewer outliers with both required.

### Chromosome Plots

**Important:** If you want to make the ideogram plots, you will need to run BGC and the previous R functions twice: Once for SNPs aligned only to your study organism's transcriptome, and a second time for all genome-wide loci (i.e. unplaced scaffolds). The transcriptome loci names should have the GenBank Transcript IDs (also found in a GFF file), and the genome-wide loci should have scaffold IDs as the loci names.

For this part, you need a closely related reference genome that is assembled at the chromosome level. Second, your model organisms needs to have at least a scaffold-level genome and a transcriptome. You will also need a GFF file for the annotations.

**If you don't have all of those, you won't be able to do the chromosome plot.**

#### Align scaffold-level Assembly to a Reference Genome.

You need to run some a priori analyses first.

You need to use minimap2 for this part. https://github.com/lh3/minimap2

1. To map the assembly data to the reference genome, name the reference chromosomes in a fasta file something like "chr1", "chr2", etc. The important thing is that they have a string prefix and an integer at the end. This will be important downstream.

2. Remove unplaced scaffolds from the reference genome's fasta file.

3. Concatenate the genome-wide and transcriptome fasta files into one file.

4. Run minimap2. Tested with minimap2 v2.17.  
  + Example command: 
  + ```minimap2 --cs -t 4 -x asm20 -N 100 ref.fasta assembly.fasta > refmap_asm20.paf```  
  
5. You will want to adjust asm20 to suit how closely related your reference genome is to your study organism. asm 20 is suitable if the average sequence divergence is ~10%, and it allows up to 20% divergence. asm10 is suitable for 5% average, allowing up to 10%. asm5 is for divergence of a few percent and up to 5%. 

6. You also will want to save the output as a paf file (default in minimap2).  

7. Next, run PAFScaff. https://github.com/slimsuite/pafscaff
  + PAFScaff cleans up and improves the mapping.
  + One of the output files from PAFScaff will be required to make the chromosome plot.
  + **Important**: When running PAFScaff, set refprefix=ref_chromosome_prefix, newprefix=query, and unplaced=unplaced_ and sorted=RefStart
  + E.g., 
  + ```python pafscaff.py pafin=refmap_asm20.paf basefile=refmap_asm20_pafscaff reference=refchr.fasta assembly=assembly.fasta refprefix=chr newprefix=query unplaced=unplaced_ sorted=RefStart forks=16```
  
  + Once PAFScaff is done running, you can move on with the chromosome plots.
  
#### Make Chromosome Plots

**These steps assume you have run BGC, combine_bgc_output() and get_bgc_outliers() for both transcriptome loci and genome-wide (i.e. unplaced scaffolds) loci.**  

* Read in the GFF file using the parseGFF function.

```
gff <- parseGFF(gff.filepath = "./exampledata/genes.gff")
```

* Now join the GFF annotations with the transcriptome dataset's transcript IDs.

```
genes.annotated <-
  join_bgc_gff(prefix = "population1",
               outlier.list = gene.outliers,
               gff.data = gff,
               scafInfoDIR = "./scaffold_info")
```

The scafInfoDIR parameter allows you to save the annotated output (e.g. with gene names) to this directory.  

* Get outliers for unplaced scaffolds. Needed for chromosome plots.  

```
# Aggregate the runs
bgc.full <-
  combine_bgc_output(results.dir = "exampledata/fulldataset",
                     prefix = "full_population1")

# Find the outliers
full.outliers <-
  get_bgc_outliers(
    df.list = bgc.full,
    admix.pop = "population1",
    popmap = file.path("./exampledata/popmap.txt"),
    loci.file = file.path("./exampledata/fulldataset/full_population1_bgc_loci.txt"))
  )
```

#### Plot Ideograms

To plot, you need the genome-wide outliers, the annotated transcriptome data, and the *.scaffolds.tdt output file from PAFScaff.

If some chromosomes didn't have any outliers on them, they might not get plotted. If that's the case, you can use the missing.chrs and miss.chr.length arguments to include them. You just need their names in a vector and a vector of each chromosome's length (in base pairs).


```
plot_outlier_ideogram(
  prefix = "population1",
  outliers.genes = genes.annotated,
  outliers.full.scaffolds = full.outliers,
  pafInfo = "exampledata/refmap_asm20.scaffolds.tdt", # This is the PAFScaff output file
  plotDIR = "./plots",
  missing.chrs = c("chr11", "chr21", "chr25"), # If some chromosomes didn't have anything aligned to them
  miss.chr.length = c(4997863, 1374423, 1060959)
)
```

![Ideogram Plot: Alpha and Beta Outliers.](vignettes/population1_chromosome.png)

This plot gets saved as an SVG file in plotDIR and by default a PDF file (saved in the current working directory). But you can change the PDF output to PNG or JPG if you want. See ?plot_outlier_ideogram

You can also mess with the colors and the band sizes. The bands by default are set much larger than the one base pair SNP position for visualization and clarity. If you want to make them larger for the genes and/or the unplaced scaffolds, you can. And you can adjust the colors of the alpha and beta bands separately by specifying a character vector colors (Rcolorbrewer or hex code) to the colorset1 (alpha) and colorset2 (beta) parameters.  E.g., 

```
plot_outlier_ideogram(
                      prefix = "population1",
                      outliers.genes = genes.annotated,
                      outliers.full.scaffolds = full.outliers,
                      pafInfo = "exampledata/refmap_asm20.scaffolds.tdt", # This is the PAFScaff output file
                      plotDIR = "./plots",
                      missing.chrs = c("chr11", "chr21", "chr25"), # If some chromosomes didn't have anything aligned to them
                      miss.chr.length = c(4997863, 1374423, 1060959),
                      gene.size = 100000, # adjust size of known gene bands
                      other.size = 50000, # adjust size of unplaced scaffold bands
                      colorset1 = c("green", "white", "blue"), # alpha colors
                      colorset2 = c("red", "yellow", "purple"), # beta colors
                      convert_svg = "png" # save as png instead of pdf
)
```

## Finding Important Raster Layers  

We can get a bunch of raster layers and determine which are the most important with regards to species distribtution modeling. This info can then be used to correlate significant INTROGRESS loci (see below) with the most important environmental features. We will use a wrapper package called ENMeval to run MAXENT for the species distribution modeling. You will need the maxent.jar file to be placed in dismo's java directory, which should be where R installed your dismo package. E.g. mine was placed here, where my dismo R package is installed:   

```"C:/Users/btm/Documents/R/win-library/3.6/dismo/java/maxent.jar"```  

### Prepare and Load Rasters

You will need all your raster files in one directory, with no other files. E.g., the 19 BioClim layers from https://worldclim.org/. The rasters also all need to be the same extent and resolution. If you got them all from WorldClim, they should all be the same. But if you add layers from other sources you'll need to resample the ones that don't fit. 

See my scripts/prepareRasters.R script for examples of how to prepare layers that are different. If you get an error loading the rasters into a stack, this is the problem and you will need to resample some rasters.

Also of note, the raster layers load in alphabetical order of filenames. So if you want to e.g. load a categorical layer first, prepend an earlier letter to the filename. 

You will need a file with sample information. This file should be four comma-delimited columns in a specific order:  

1. IndividualIDs
2. PopulationIDs
3. Latitude (in decimal degrees)
4. Longitude (in decimal degrees)

You will get an error if one or more of your samples falls on an NA value for any of your input rasters. If this happens, just remove the offending individual(s) from the sample.file file and re-run prepare_rasters(). The error message will print out a list of individuals with NA values in each raster layer.

Then you can run prepare_rasters():  

```
envList <- 
  prepare_rasters(
    raster.dir = "./rasters",
    sample.file = "sampleinfo.csv",
    header = TRUE,
    bb.buffer = 0.5,
    plotDIR = "./plots"
    )
```  

You can change the bb.buffer argument to a larger or smaller value. prepare_rasters() will crop your raster layers to the sampling locality extent, and if bb.buffer = 0.5, a 0.5 degree buffer will be added to the sampling extent. This is useful for making the background points later.  

If your sample.file has a header line, set header = TRUE. If not, set header = FALSE.  

### Generate Background Points

Then you can run partition_raster_bg(). This will generate a bunch of background points for when you run MAXENT.  

```
bg <- 
  partition_raster_bg(
    env.list = envList, plotDIR = "./plots")
```  

This will also generate two plots.  

1. All your input rasters with sample localities overlaid as points.  
2. Background points for several partitioning methods. See the ENMeval vignette for more info on bg partitions.  
  + The background partition methods that ClinePlotR supports are: block, checkerboard1, and checkerboard2.  

### Run ENMeval

Here, you can subset and remove the envList object to reduce your memory footprint if ENMeval runs out of memory. If you don't want to lose envList you can save it as an RDS object before removing it. That way you don't have to re-run the whole environmental pipeline if you want to re-load it.  

```
saveRDS(saveRDS(envList, file = "./envList.rds"))
envs.fg <- envList[[1]]
coords <- envList[[3]]
rm(envList) # Removes envList object from global environment
gc() # This will perform garbage collection to release system memory resources
```

If you decide you want to reload envList again, just do:  

```envList <- readRDS("./envList.rds")```

You might need to increase the amount of memory that rJava can use if you get an out of memory error:  

```options(java.parameters = "-Xmx16g")```

This sets the amount of memory that rJava can use to 16 GB.  

Now you can run ENMeval.  

```
eval.par <- runENMeval(envs.fg = envs.fg,
                       bg = bg, 
                       parallel = TRUE,
                       categoricals = 1,
                       partition.method = "checkerboard1",
                       coords = coords,
                       np = 4)
```

This will run ENMeval with four parallel processes. FYI, if running in parallel it doesn't have a progress bar, and it uses np times the amount of RAM. So if you still run out of memory even after increasing the memory available to rJava, try reducing the number of processes you are running in parallel. 

You can try some other options too: 

```
eval.par <- runENMeval(envs.fg = envs.fg, # envList[[1]]
                       bg = bg, # Returned from partition_raster_bg()
                       parallel = FALSE, # Don't run in parallel
                       categoricals = c(1, 2), # Specify first two layers as categorical (e.g. land cover)
                       partition.method = "checkerboard2",
                       coords = coords, # envList[[3]]
                       RMvalues = seq(0.5, 5, 0.5), # Runs regularization multipliers from 0.5 to 5 in 0.5 increments
                       agg.factor = c(3, 3), # Changes aggregation.factor for background partition
                       feature.classes c("L", "LQ", "LQP") # Specify which feature classes to run with MAXENT
                       algorithm = "maxnet" # Use maxnet instead of maxent
                       )
```

See ?ENMeval and the ENMeval vignette for more info on what you can do with the package.  

### Summarize and Plot ENMeval results

Now you can summarize and plot the ENMeval results. This was all taken from the ENMeval vignette.  

```
summarize_ENMeval(
  eval.par = eval.par,
  plotDIR = "./plots",
  minLat = 25, # Adjust these to your coordinate frame
  maxLat = 45,
  minLon = -100,
  maxLon = -45
  )
```

This will make a bunch of plots and CSV files in plotDIR, including the MAXENT precictions, lambda results, best model based on AICc scores, various plots showing how the regularization multipliers and feature classes affect AICc scores, and a barplot showing raster layer Permutation Importance.  

If your raster filenames are long, they will likely run off the Permutation Importance barplot. You can adjust the margins of the plot using the imp.margins parameter. There are some other plot adjustment parameters you can try as well:  

```
summarize_ENMeval(
  eval.par = eval.par,
  plotDIR = "./plots",
  minLat = 25, # Adjust to your specific lat/lon extent
  maxLat = 45,
  minLon = -100,
  maxLon = -45,
  imp.margins = c(15.1, 4.1, 3.1, 2.1), # c(bottom, left, top, right),
  examine.predictions = c("L", "LQ", "LQP"), # Should be the same as above
  RMvalues = seq(0.5, 5, 0.5), # Should be the same as above
  plot.width = 10, # Change plot width (all plots)
  plot.height = 10, # Change plot height (all plots)
  niche.overlap = TRUE # If TRUE, runs ENMeval's calc.niche.overlap function; might take a while
  )
```

If you want to create the response curves for the best model: 

```
pdf(file = "./plots/responseCurves.pdf", width = 7, height = 7)
dismo::response(eval.par@models[[28]])
dev.off()
```

You can inspect eval.par@models to find the model with the best delta AICc. In this case, model 28 was the best model, so I ran dismo::response() on eval.par@models[[28]].  

You can then run INTROGRESS and start the next part of this pipeline.  

## INTROGRESS Genomic Clines X Environmental Data

Now that we have the important raster, we can use it to plot INTROGRESS genomic clines ~ environment. First, we need to extract the raster values for each sample point. We have included a function that does this. You just need the envList object generated from the prepare_rasters() function above. If you saved this object for later use, you can just reload it with readRDS().

```
envList <- readRDS("./envList.rds")
rasterPoint.list <- extractPointValues(envList)
```

Now we run INTROGRESS. To do so, we need the INTROGRESS input files (see ?introgress). We have included a wrapper function to run INTROGRESS easier. You can adjust some of the settings. Make sure to remove individuals from the INTROGRESS input files that occurred on NA raster values.

```
# Run INTROGRESS
test1 <- runIntrogress(
  p1.file = file.path(dataDIR, "p1data.txt"),
  p2.file = file.path(dataDIR, "p2data.txt"),
  admix.file = file.path(dataDIR, "admix_RemovedNA.txt"),
  loci.file = file.path(dataDIR, "loci.txt"),
  clineLabels = c("pop1", "Het", "pop2"),
  minDelt = 0.8,
  prefix = "test1",
  outputDIR = file.path(dataDIR, "outputFiles"),
  sep = "\t",
  fixed = FALSE,
  pop.id = FALSE,
  ind.id = FALSE
)
```  

This will run both the perumtation and parametric INTROGRESSION tests. See ?introgress.

So, you need the P1, P2, admixed, and loci files. See ?introgress.
You can also change the field separated in the INTROGRESS input files by using sep. E.g.,  
```sep = ","```  

You can set clineLabels to reflect your population names. It needs to be a character vector of length == 3.  

You can set the minDelt parameter to a different value if you want. This parameter only tests outlier loci that have allele frequency differentials > minDelt. So ideally this should be set high (>0.6). You can try different settings. Default is 0.8. If you don't recover any loci, lower minDelt.  

If your SNPs are fixed between parental populations, set fixed = TRUE and it will also generate a triangle plot of Interspecific Heterozygosity ~ Hybrid Index.  

pop.id and ind.id are used if your input files have these headers.  

Once this finishes running, you can use another of our functions to subset a full list of individuals to just those included in the INTROGRESS analysis. E.g.,

```
# Subset individuals for only the populations run in INTROGRESS
rasterPoint.list.subset <-
  lapply(rasterPoint.list,
         subsetIndividuals,
         file.path(dataDIR, "test1_inds.txt"))
```

This will remove individuals from rasterPoint.list that were not in "test1_inds.txt". So use test1_inds.txt as a list of individuals in your INTROGRESS analysis.  

Then you can generate the plots:  

```
# Correlate genomic clines/hybrid index with environment/lat/lon
clinesXenvironment(
  clineList = test1,
  rasterPointValues = rasterPoint.list.subset,
  clineLabels = c("pop1", "Het", "pop2"),
  outputDIR = file.path(dataDIR, "outputFiles", "test1Plots"),
  clineMethod = "permutation",
  prefix = "test1",
  cor.method = "auto"
)
```

Here, you can change the clineMethod to either "permutation" or "parametric". See ?introgress.  


This will run for latitude, longitude, and all the raster layers from envList. If you want to run it for only some raster layers, just use the rastersToUse parameter, which is just an integer vector containing the indexes for each raster layer you want to include. You can get which raster is which by inspecting the envList[[1]]@data object.  

```
# Correlate genomic clines/hybrid index with environment/lat/lon
clinesXenvironment(
  clineList = test1,
  rasterPointValues = rasterPoint.list.subset,
  clineLabels = c("pop1", "Het", "pop2"),
  outputDIR = file.path(dataDIR, "outputFiles", "test1Plots"),
  clineMethod = "permutation",
  prefix = "test1",
  cor.method = "auto",
  rastersToUse = c(1, 5, 7, 19, 23)
)
```

You can also change the correlation method parameter (cor.method) to something else supported by cor.test. Possible options include:  
```c("auto", "pearson", "kendall", "spearman")```

If you use auto, it will test for normally distributed data and, if present, will use Pearson's correlation. If not, it will use Kendall. But if you want to use Spearman's, you need to change the cor.method parameter to "spearman".  

clinesXenvironment will generate three output files:  

1. "prefix_clinesXLatLon.pdf", which contains:  
  + Genomic Clines ~ Latitude and Longitude
  + Hybrid Index ~ Latitude and Longitude
2. "prefix_clinesXenv.pdf", which contains:  
  + Genomic Clines ~ each raster layer
  + Hybrid Index ~ each raster layer
3. "prefix_corrSummary.csv"
  + This contains correlation tests for all the environmental files plus latitude and longitude.
  
Here are some example plots that clinesXenvironment can make:  

Genomic Clines ~ Longitude  
<img src="vignettes/genomicClineXlongitude.png" width="50%">     

Hybrid Index ~ Longitude  
<img src="vignettes/hybridIndexXLongitude.png" width="50%">     

Genomic Cline ~ Raster Layers (e.g. Here we used BioClim1)   
<img src="vignettes/genomicClineXraster_bioclim1.png" width="50%">  

Hybrid Index ~ Raster Layers (e.g. Here we used BioClim1)  
<img src="vignettes/hybridIndexXraster_bioClim1.png" width="50%">  


