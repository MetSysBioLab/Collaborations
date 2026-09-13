# ============================================================
# INSTALL PACKAGES FOR scRNA-seq / HTO / Seurat ANALYSIS
# Windows | R 4.4.1 | Rtools44 | Bioconductor 3.19
# ============================================================

options(
  repos = c(CRAN = "https://cran.r-project.org"),
  timeout = 1200
)

# ----------------------------
# 0. Verify build tools (Rtools44) are visible to R
# ----------------------------

if (!requireNamespace("pkgbuild", quietly = TRUE)) {
  install.packages("pkgbuild")
}

has_tools <- pkgbuild::has_build_tools(debug = TRUE)

if (!has_tools) {
  stop(
    "Rtools44 is not detected on PATH. Install Rtools44 from CRAN ",
    "(https://cran.r-project.org/bin/windows/Rtools/) and restart R before continuing."
  )
} else {
  message("Rtools44 detected. Proceeding with installation.")
}

# Install a package only if it is not already installed
install_if_missing <- function(pkgs, type = getOption("pkgType")) {
  missing <- pkgs[!pkgs %in% rownames(installed.packages())]
  
  if (length(missing) > 0) {
    install.packages(
      missing,
      dependencies = TRUE,
      type = type
    )
  } else {
    message("All requested CRAN packages are already installed.")
  }
}

# Robust installer that retries with libcurl if SSL/download errors occur
install_binary_robust <- function(pkg) {
  ok <- tryCatch({
    install.packages(pkg, type = "binary")
    requireNamespace(pkg, quietly = TRUE)
  }, error = function(e) FALSE, warning = function(w) FALSE)
  
  if (!ok) {
    message("Retrying '", pkg, "' with method = 'libcurl' after failure...")
    tryCatch({
      install.packages(pkg, type = "binary", method = "libcurl")
    }, error = function(e) {
      message("Still failed for '", pkg, "'. Error: ", conditionMessage(e))
    })
  }
}

# ----------------------------
# 1. CRAN packages
# ----------------------------

cran_pkgs <- c(
  "Seurat",
  "SeuratObject",
  "harmony",
  "SoupX",
  "ggplot2",
  "ggrepel",
  "dplyr",
  "tidyr",
  "readr",
  "data.table",
  "stringr",
  "patchwork",
  "cowplot",
  "ggridges",
  "viridis",
  "viridisLite",
  "RColorBrewer",
  "future",
  "Matrix",
  "Rcpp",
  "hdf5r",
  "reticulate",
  "leiden",
  "clustree",
  "plotly",
  "qs2"
)

install_if_missing(cran_pkgs)

# xgboost is scDblFinder's main dependency and the most common Windows
# failure point (SSL/download errors or compilation errors).
if (!requireNamespace("xgboost", quietly = TRUE)) {
  message("Installing xgboost as a binary...")
  install_binary_robust("xgboost")
}

# ----------------------------
# 2. Bioconductor installer
# ----------------------------

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# R 4.4.1 pairs with Bioconductor 3.19. Force this explicitly so BiocManager
# does not silently resolve to a mismatched Bioc version.
BiocManager::install(version = "3.19", ask = FALSE, update = FALSE)

message("Bioconductor version in use: ", BiocManager::version())

bioc_status <- BiocManager::valid()
if (isTRUE(bioc_status) || is.data.frame(bioc_status) == FALSE) {
  message("BiocManager::valid() reports package set is consistent.")
} else {
  message("BiocManager::valid() found inconsistencies:")
  print(bioc_status)
}

# ----------------------------
# 3. Bioconductor packages
# ----------------------------

# Core low-level infra packages that scDblFinder depends on.
# force = TRUE ensures BiocManager does not skip a package just because
# it thinks an equal/newer version is already registered, even when the
# library files are actually missing or incomplete.
bioc_infra_pkgs <- c(
  "BiocParallel",
  "BiocNeighbors",
  "BiocSingular",
  "SingleCellExperiment",
  "SummarizedExperiment",
  "scuttle",
  "scran",
  "scater"
)

for (pkg in bioc_infra_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    BiocManager::install(pkg, ask = FALSE, update = FALSE, type = "binary", force = TRUE)
  }
}

# scDblFinder: force reinstall so it is not silently skipped, with a
# fallback to the GitHub/Bioconductor git mirror if the binary install fails.
if (!requireNamespace("scDblFinder", quietly = TRUE)) {
  message("Installing scDblFinder...")
  tryCatch({
    BiocManager::install("scDblFinder", ask = FALSE, update = FALSE, type = "binary", force = TRUE)
  }, error = function(e) {
    message("Binary install failed, retrying from Bioconductor Git mirror...")
    tryCatch({
      BiocManager::install("plger/scDblFinder", ask = FALSE, update = FALSE, force = TRUE)
    }, error = function(e2) {
      message("scDblFinder installation failed. Error message:")
      message(conditionMessage(e2))
    })
  })
}

# Remaining Bioconductor packages
bioc_pkgs <- c(
  "DropletUtils",
  "glmGamPoi",
  "MAST",
  "edgeR",
  "limma",
  "DESeq2",
  "ComplexHeatmap",
  "Nebulosa",
  "EnhancedVolcano",
  "AnnotationDbi",
  "org.Hs.eg.db",
  "GO.db",
  "clusterProfiler",
  "enrichplot",
  "GOSemSim"
)

missing_bioc <- bioc_pkgs[
  !vapply(
    bioc_pkgs,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
]

if (length(missing_bioc) > 0) {
  BiocManager::install(
    missing_bioc,
    ask = FALSE,
    update = FALSE,
    type = "binary"
  )
} else {
  message("All requested Bioconductor packages are already installed.")
}

# ----------------------------
# 4. Optional scATAC packages
# ----------------------------

# These are not required for your RNA + HTO workflow.
# Run this block only if you will analyze scATAC-seq data.

# install_if_missing("Signac")
#
# atac_bioc_pkgs <- c(
#   "GenomeInfoDb",
#   "GenomicRanges",
#   "EnsDb.Hsapiens.v86",
#   "JASPAR2020",
#   "TFBSTools",
#   "BSgenome.Hsapiens.UCSC.hg38",
#   "motifmatchr",
#   "chromVAR"
# )
#
# BiocManager::install(
#   atac_bioc_pkgs,
#   ask = FALSE,
#   update = FALSE
# )

# ----------------------------
# 5. Verify packages needed now
# ----------------------------

required_now <- c(
  "Seurat",
  "SeuratObject",
  "ggplot2",
  "dplyr",
  "tidyr",
  "patchwork",
  "viridis",
  "RColorBrewer",
  "future",
  "SoupX",
  "harmony",
  "scDblFinder"
)

status <- data.frame(
  package = required_now,
  installed = vapply(
    required_now,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
)

print(status)

missing_now <- status$package[!status$installed]

if (length(missing_now) == 0) {
  cat("\nSUCCESS: Core Seurat/scRNA-seq packages are installed.\n")
  cat("Restart R, then load packages and run your analysis.\n")
} else {
  cat("\nThese packages are still missing:\n")
  cat(paste0(" - ", missing_now, collapse = "\n"), "\n")
  cat(
    "\nIf a package is still missing, run these two diagnostic lines\n",
    "and share the exact printed error text:\n",
    "  BiocManager::valid()\n",
    "  tools::Rcmd('config CC')\n"
  )
}

# ============================================================
# LOAD PACKAGES FOR scRNA-seq / HTO / Seurat ANALYSIS
# Run this after restarting R following the install script.
# ============================================================

# ----------------------------
# 1. Core Seurat object handling
# ----------------------------
library(Seurat)          # main scRNA-seq analysis framework
library(SeuratObject)    # underlying S4 object classes used by Seurat

# ----------------------------
# 2. Single-cell infrastructure (Bioconductor)
# ----------------------------
library(SingleCellExperiment)  # standard container class for sc data
library(SummarizedExperiment)  # base class SCE builds on
library(scuttle)                # utility functions for QC / normalization
library(scran)                   # feature selection, normalization, clustering helpers
library(scater)                  # QC metrics and visualization for SCE objects
library(BiocParallel)           # parallel backend used by several Bioc packages
library(BiocNeighbors)          # fast nearest-neighbor search (used by scDblFinder, scran)
library(BiocSingular)           # PCA/SVD backend used by scran/scater

# ----------------------------
# 3. QC, doublets, and ambient RNA
# ----------------------------
library(scDblFinder)     # doublet detection
library(SoupX)            # ambient RNA / background correction
library(DropletUtils)    # raw/filtered matrix handling, empty droplet detection

# ----------------------------
# 4. Batch integration
# ----------------------------
library(harmony)          # batch correction / dataset integration

# ----------------------------
# 5. Differential expression and enrichment
# ----------------------------
library(MAST)              # single-cell differential expression
library(glmGamPoi)        # fast GLMs for count data (used by SCTransform in Seurat v5)
library(edgeR)             # bulk-style DE, dispersion estimation
library(limma)             # linear modeling, often used with edgeR/voom
library(DESeq2)            # DE analysis for pseudobulk / bulk-style comparisons
library(AnnotationDbi)    # annotation database interface
library(org.Hs.eg.db)     # human gene ID annotation (swap for org.Mm.eg.db if mouse)
library(GO.db)              # Gene Ontology term database
library(clusterProfiler)  # functional enrichment analysis (GO, KEGG, etc.)
library(enrichplot)        # visualization for clusterProfiler results
library(GOSemSim)          # semantic similarity between GO terms

# ----------------------------
# 6. Plotting and visualization
# ----------------------------
library(ggplot2)           # base plotting grammar
library(ggrepel)           # non-overlapping text labels on plots
library(patchwork)         # combine multiple ggplot panels
library(cowplot)            # additional plot composition utilities
library(ggridges)           # ridge plots (useful for HTO/marker distributions)
library(viridis)            # perceptually uniform color scales
library(viridisLite)        # lightweight viridis palette dependency
library(RColorBrewer)      # additional color palettes
library(plotly)             # interactive plots
library(ComplexHeatmap)    # advanced heatmaps (marker genes, module scores)
library(Nebulosa)           # density-based feature plots (kernel density on UMAP/tSNE)
library(EnhancedVolcano)   # volcano plots for DE results

# ----------------------------
# 7. Data wrangling
# ----------------------------
library(dplyr)              # data manipulation
library(tidyr)               # reshaping data
library(readr)               # fast file reading
library(data.table)         # high-performance tables for large matrices
library(stringr)             # string manipulation

# ----------------------------
# 8. Performance, I/O, and Python interop
# ----------------------------
library(future)              # parallelization backend used by Seurat
library(Matrix)              # sparse matrix support (core to scRNA-seq data)
library(Rcpp)                 # C++ interface used by many dependencies
library(hdf5r)                # HDF5 file support (10x .h5 files)
library(reticulate)          # Python interop (e.g., for UMAP/leiden backends)
library(leiden)               # Leiden clustering algorithm
library(clustree)            # visualize clustering resolution trees
library(qs2)                   # fast serialization for saving/loading large R objects

# ----------------------------
# 9. Confirm everything loaded without error
# ----------------------------
message("All packages loaded successfully. Session ready for scRNA-seq/HTO analysis.")

# Optional: set global options commonly used in Seurat v5 workflows
options(future.globals.maxSize = 8 * 1024^3)  # raise limit for parallel processing (8 GB)
plan("multisession", workers = 4)               # adjust worker count to your CPU cores

# =============================================================================
# STEP 1: Inspect Cell Ranger output directory structure
# Purpose: confirm exact folder layout before writing the loading code
# =============================================================================

base_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/Cell_Ranger_Outputs"

# 1. Does the base directory exist?
cat("Base directory exists:", dir.exists(base_dir), "\n\n")

# 2. List everything directly inside it (top-level sample folders, etc.)
cat("---- Top-level contents of base_dir ----\n")
top_level <- list.files(base_dir, full.names = FALSE)
print(top_level)

# 3. Recursively list the full folder tree, directories only, up to 6 levels deep
#    This shows the real nesting (per_sample_outs, count, etc.) without dumping
#    every file inside every matrix folder.
cat("\n---- Full directory tree (folders only, max depth 6) ----\n")
all_dirs <- list.dirs(base_dir, recursive = TRUE, full.names = TRUE)

# Trim to a reasonable depth so the tree isn't overwhelming
rel_dirs <- gsub(paste0("^", gsub("\\\\", "/", base_dir)), "", gsub("\\\\", "/", all_dirs))
depth <- lengths(regmatches(rel_dirs, gregexpr("/", rel_dirs)))
print(all_dirs[depth <= 6])

# 4. For the FIRST top-level folder found, list its contents one level down,
#    two levels down, and three levels down — to see where the matrix files sit
if (length(top_level) > 0) {
  first_sample <- top_level[1]
  cat("\n---- Drilling into first sample folder:", first_sample, "----\n")
  
  lvl1 <- file.path(base_dir, first_sample)
  cat("\nLevel 1 (", lvl1, "):\n")
  print(list.files(lvl1))
  
  lvl1_dirs <- list.dirs(lvl1, recursive = FALSE)
  for (d in lvl1_dirs) {
    cat("\nLevel 2 (", d, "):\n")
    print(list.files(d))
  }
}

# 5. Search the whole tree for key Cell Ranger output files/folders
#    (matrix.mtx, features.tsv, barcodes.tsv, or .h5 files) so we know exactly
#    where the actual count matrices live, regardless of folder naming.
cat("\n---- Locating actual matrix files anywhere under base_dir ----\n")
matrix_hits <- list.files(
  base_dir,
  pattern = "matrix\\.mtx|features\\.tsv|barcodes\\.tsv|filtered_feature_bc_matrix|\\.h5$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
print(matrix_hits)

# =============================================================================
# STEP 2: Inspect features.tsv.gz to confirm feature types present
# Purpose: determine whether Read10X() will return a list (GEX + HTO)
#          or a single matrix (GEX only) for these samples
# =============================================================================

base_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/Cell_Ranger_Outputs"

sample_ids <- c("NA1", "NA2", "NA3", "NA4", "NA5", "NA6", "NA7", "NA8")

for (sample_id in sample_ids) {
  features_path <- file.path(base_dir, sample_id, "features.tsv.gz")
  
  cat("\n----", sample_id, "----\n")
  
  if (!file.exists(features_path)) {
    cat("  features.tsv.gz NOT FOUND\n")
    next
  }
  
  features <- read.delim(features_path, header = FALSE, stringsAsFactors = FALSE)
  
  # Standard Cell Ranger features.tsv columns: ID, Name, Type
  cat("  Number of columns:", ncol(features), "\n")
  cat("  Number of rows (features):", nrow(features), "\n")
  
  if (ncol(features) >= 3) {
    type_counts <- table(features[[3]])
    cat("  Feature type counts:\n")
    print(type_counts)
    
    # If Antibody Capture / HTO features exist, show their names
    if ("Antibody Capture" %in% names(type_counts)) {
      hto_names <- features[features[[3]] == "Antibody Capture", 2]
      cat("  Antibody Capture / HTO feature names found:\n")
      print(hto_names)
    }
  } else {
    cat("  Only", ncol(features), "column(s) present — likely Gene Expression only, no type column\n")
  }
}

# =============================================================================
# STEP 3: Load Cell Ranger data into Seurat objects (Gene Expression + HTO)
# Confirmed structure: each sample folder contains barcodes.tsv.gz,
# features.tsv.gz, matrix.mtx.gz directly (no per_sample_outs nesting).
# All 8 samples contain all 4 hashtags (B0301-B0304) in features.tsv.gz;
# the relevant 2-per-sample subsetting happens later at the demux step.
#
# METADATA NOTE:
# Only sample_id (physical sample of origin) is added here. Hashtag
# identity, treatment, sample_group, and pair are NOT added yet — those
# depend on HTODemux() classification, which runs in Step 4.
# =============================================================================

library(Seurat)
library(qs2)

set.seed(42)

# ----------------------------
# Fixed absolute paths — used identically in every step of this pipeline
# ----------------------------

data_dir_base  <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/Cell_Ranger_Outputs"
analysis_dir   <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir         <- file.path(analysis_dir, "qsfiles")
results_dir    <- file.path(analysis_dir, "results")   # PDFs, CSVs, plots

if (!dir.exists(qs_dir))      dir.create(qs_dir, recursive = TRUE)
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

sample_ids <- c("NA1", "NA2", "NA3", "NA4", "NA5", "NA6", "NA7", "NA8")

# ----------------------------
# Hashtag to treatment / design reference (used in later steps too)
# ----------------------------

cat("=============================================================================\n")
cat("Hashtag Barcode to Treatment Mapping:\n")
cat("  B0301 = Untreated\n")
cat("  B0302 = aCD3\n")
cat("  B0303 = aCD3+BDC2.5\n")
cat("  B0304 = aCD3+Polyclonal\n")
cat("=============================================================================\n")
cat("Sample Design:\n")
cat("  Condition A samples (NA1, NA3, NA5, NA7): B0301 (Untreated) + B0302 (aCD3)\n")
cat("  Condition B samples (NA2, NA4, NA6, NA8): B0303 (aCD3+BDC2.5) + B0304 (aCD3+Polyclonal)\n")
cat("=============================================================================\n\n")

# ----------------------------
# Load each sample: gene expression -> Seurat object, HTO -> separate assay
# ----------------------------

seurat_list <- list()

for (sample_id in sample_ids) {
  
  cat("Loading data for", sample_id, "\n")
  
  sample_data_dir <- file.path(data_dir_base, sample_id)
  
  if (!dir.exists(sample_data_dir)) {
    stop(paste("Data directory does not exist:", sample_data_dir))
  }
  
  # Read10X returns a named list here because features.tsv.gz contains
  # both 'Gene Expression' and 'Antibody Capture' feature types
  data <- Read10X(data.dir = sample_data_dir)
  
  if (!is.list(data) || !"Gene Expression" %in% names(data)) {
    stop(paste("Unexpected Read10X() output structure for", sample_id))
  }
  
  seurat_obj <- CreateSeuratObject(
    counts = data$`Gene Expression`,
    project = sample_id,
    min.cells = 3,
    min.features = 200
  )
  
  # Explicit sample_id metadata column (physical sample of origin)
  seurat_obj$sample_id <- sample_id
  
  if ("Antibody Capture" %in% names(data)) {
    seurat_cells <- colnames(seurat_obj)
    cells_to_use <- intersect(seurat_cells, colnames(data$`Antibody Capture`))
    
    cat("  Cells in Seurat object:", ncol(seurat_obj), "\n")
    cat("  Hashtag barcodes found:", paste(rownames(data$`Antibody Capture`), collapse = ", "), "\n")
    
    if (length(cells_to_use) > 0) {
      hto_data <- data$`Antibody Capture`[, cells_to_use, drop = FALSE]
      seurat_obj[["HTO"]] <- CreateAssayObject(counts = hto_data)
      cat("  Added", nrow(hto_data), "HTO features for", ncol(hto_data), "cells\n")
    } else {
      warning("No overlapping cells between GEX and HTO matrices for ", sample_id)
    }
  } else {
    warning("No Antibody Capture data found for ", sample_id)
  }
  
  cat("  Final Seurat object:", ncol(seurat_obj), "cells,", nrow(seurat_obj), "genes\n\n")
  
  seurat_list[[sample_id]] <- seurat_obj
}

# ----------------------------
# Quick sanity check across all samples
# ----------------------------

cat("=============================================================================\n")
cat("LOAD SUMMARY\n")
cat("=============================================================================\n")
for (sample_id in sample_ids) {
  obj <- seurat_list[[sample_id]]
  has_hto <- "HTO" %in% names(obj@assays)
  cat(sprintf("  %-4s : %5d cells | %5d genes | HTO assay present: %s\n",
              sample_id, ncol(obj), nrow(obj), has_hto))
}
cat("=============================================================================\n")
cat("\nMetadata added so far: sample_id only.\n")
cat("Hashtag identity / treatment / sample_group / pair will be added in Step 4/5.\n")

# ----------------------------
# Save — always to the fixed qs_dir location
# ----------------------------

out_path <- file.path(qs_dir, "seurat_list_raw.qs2")
qs_save(seurat_list, file = out_path)
cat("\nSaved raw Seurat object list to:\n ", out_path, "\n")

# =============================================================================
# STEP 4: HTO Demultiplexing (per sample)
# Subsets each sample's HTO assay to its 2 expected hashtags, runs
# CLR normalization + HTODemux, saves diagnostic plots, and classifies
# each cell as Singlet / Doublet / Negative.
#
# METADATA NOTE: hashtag_id / classification first becomes known here.
# treatment / sample_group / pair are added in Step 5, after filtering
# to singlets.
# =============================================================================

library(Seurat)
library(qs2)

set.seed(42)

# ----------------------------
# Fixed absolute paths — identical across all steps
# ----------------------------

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

if (!dir.exists(qs_dir))      dir.create(qs_dir, recursive = TRUE)
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

# ----------------------------
# Load Step 3 output
# ----------------------------

in_path <- file.path(qs_dir, "seurat_list_raw.qs2")
seurat_list <- qs_read(in_path)
cat("Loaded raw Seurat object list from:\n ", in_path, "\n\n")

sample_ids <- names(seurat_list)

condition_a_samples <- c("NA1", "NA3", "NA5", "NA7")  # expected: B0301, B0302
condition_b_samples <- c("NA2", "NA4", "NA6", "NA8")  # expected: B0303, B0304

expected_htos_map <- list()
for (s in condition_a_samples) expected_htos_map[[s]] <- c("B0301", "B0302")
for (s in condition_b_samples) expected_htos_map[[s]] <- c("B0303", "B0304")

demux_list <- list()

for (sample_id in sample_ids) {
  
  cat("\n========================================\n")
  cat("Demultiplexing", sample_id, "\n")
  cat("========================================\n")
  
  seurat_obj <- seurat_list[[sample_id]]
  
  if (!"HTO" %in% names(seurat_obj@assays)) {
    cat("  WARNING: No HTO assay found. Marking as Undetermined.\n")
    seurat_obj$HTO_classification.global <- "Singlet"
    seurat_obj$HTO_classification <- "Undetermined"
    demux_list[[sample_id]] <- seurat_obj
    next
  }
  
  all_htos <- rownames(seurat_obj[["HTO"]])
  expected_htos <- expected_htos_map[[sample_id]]
  
  if (is.null(expected_htos)) {
    warning("Sample ", sample_id, " not assigned to a condition. Using all HTOs present.")
    expected_htos <- all_htos
  }
  
  present_htos <- intersect(expected_htos, all_htos)
  cat("  Expected HTOs:", paste(expected_htos, collapse = ", "), "\n")
  cat("  HTOs used for demultiplexing:", paste(present_htos, collapse = ", "), "\n")
  
  if (length(present_htos) == 0) {
    warning("No expected HTOs found for ", sample_id, ". Marking as Undetermined.")
    seurat_obj$HTO_classification.global <- "Singlet"
    seurat_obj$HTO_classification <- "Undetermined"
    demux_list[[sample_id]] <- seurat_obj
    next
  }
  
  hto_counts_full <- GetAssayData(seurat_obj, assay = "HTO", layer = "counts")
  hto_counts_subset <- hto_counts_full[present_htos, , drop = FALSE]
  
  seurat_obj[["HTO"]] <- CreateAssayObject(counts = hto_counts_subset)
  
  seurat_obj <- NormalizeData(seurat_obj, assay = "HTO", normalization.method = "CLR")
  
  seurat_obj <- tryCatch({
    HTODemux(seurat_obj, assay = "HTO", positive.quantile = 0.99)
  }, error = function(e) {
    cat("  ERROR during HTODemux():", conditionMessage(e), "\n")
    seurat_obj$HTO_classification.global <- "Singlet"
    seurat_obj$HTO_classification <- "Undetermined"
    seurat_obj
  })
  
  # ---- Diagnostic plots — saved to the fixed results_dir ----
  pdf_path <- file.path(results_dir, paste0(sample_id, "_HTO_demux.pdf"))
  pdf(pdf_path, width = 12, height = 8)
  
  print(RidgePlot(seurat_obj, assay = "HTO",
                  features = rownames(seurat_obj[["HTO"]]), ncol = 2))
  
  if (nrow(seurat_obj[["HTO"]]) >= 2) {
    hto_names <- rownames(seurat_obj[["HTO"]])
    print(FeatureScatter(seurat_obj, feature1 = hto_names[1], feature2 = hto_names[2]))
  }
  
  tryCatch({
    print(HTOHeatmap(seurat_obj, assay = "HTO", ncells = 5000))
  }, error = function(e) {
    cat("  Skipping HTOHeatmap (error:", conditionMessage(e), ")\n")
  })
  
  dev.off()
  cat("  Saved diagnostic plots to:", pdf_path, "\n")
  
  cat("\n  Classification summary (global):\n")
  print(table(seurat_obj$HTO_classification.global))
  cat("\n  Classification summary (hashtag):\n")
  print(table(seurat_obj$HTO_classification))
  
  demux_list[[sample_id]] <- seurat_obj
}

# ----------------------------
# Overall summary across all samples
# ----------------------------

cat("\n=============================================================================\n")
cat("DEMULTIPLEXING SUMMARY\n")
cat("=============================================================================\n")
for (sample_id in sample_ids) {
  obj <- demux_list[[sample_id]]
  cat("\n", sample_id, ":\n")
  print(table(obj$HTO_classification.global))
}
cat("=============================================================================\n")

# ----------------------------
# Save — always to the fixed qs_dir location
# ----------------------------

out_path <- file.path(qs_dir, "demux_list.qs2")
qs_save(demux_list, file = out_path)
cat("\nSaved demultiplexed Seurat object list to:\n ", out_path, "\n")

# =============================================================================
# STEP 5: Filter to singlets and add full experimental metadata
#
# This is where treatment / sample_group / pair / biological_replicate
# are added, since they depend on the confirmed HTO_classification from
# Step 4. Doublets and Negatives are dropped here — they cannot be
# reliably assigned a treatment identity.
# =============================================================================

library(Seurat)
library(qs2)
library(dplyr)

set.seed(42)

# ----------------------------
# Fixed absolute paths — identical across all steps
# ----------------------------

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

if (!dir.exists(qs_dir))      dir.create(qs_dir, recursive = TRUE)
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

# ----------------------------
# Load Step 4 output
# ----------------------------

in_path <- file.path(qs_dir, "demux_list.qs2")
demux_list <- qs_read(in_path)
cat("Loaded demultiplexed Seurat object list from:\n ", in_path, "\n\n")

sample_ids <- names(demux_list)

# ----------------------------
# Design reference tables
# ----------------------------

treatment_map <- c(
  "B0301" = "Untreated",
  "B0302" = "aCD3",
  "B0303" = "aCD3_BDC2.5",
  "B0304" = "aCD3_Polyclonal"
)

condition_a_samples <- c("NA1", "NA3", "NA5", "NA7")
condition_b_samples <- c("NA2", "NA4", "NA6", "NA8")

pair_map <- c(
  "NA1" = "Pair1", "NA2" = "Pair1",
  "NA3" = "Pair2", "NA4" = "Pair2",
  "NA5" = "Pair3", "NA6" = "Pair3",
  "NA7" = "Pair4", "NA8" = "Pair4"
)

filtered_list <- list()

for (sample_id in sample_ids) {
  
  cat("\n----", sample_id, "----\n")
  
  seurat_obj <- demux_list[[sample_id]]
  
  if (is.null(seurat_obj)) {
    cat("  ERROR: No object found for this sample. Skipping.\n")
    next
  }
  
  cells_before <- ncol(seurat_obj)
  
  # ---- Keep singlets only ----
  if (!"HTO_classification.global" %in% colnames(seurat_obj@meta.data)) {
    cat("  WARNING: No HTO_classification.global column found. Keeping all cells as-is.\n")
    seurat_singlet <- seurat_obj
  } else {
    Idents(seurat_obj) <- "HTO_classification.global"
    seurat_singlet <- subset(seurat_obj, idents = "Singlet")
  }
  
  cat("  Cells before filtering:", cells_before, "\n")
  cat("  Cells after singlet filtering:", ncol(seurat_singlet), "\n")
  
  # ---- Restrict to the 2 hashtags expected for this sample ----
  # (HTODemux was already run only on the expected pair in Step 4, so
  # HTO_classification should already only contain those 2 hashtag labels
  # among singlets — this is a safety check, not a re-filter.)
  expected_htos <- if (sample_id %in% condition_a_samples) {
    c("B0301", "B0302")
  } else if (sample_id %in% condition_b_samples) {
    c("B0303", "B0304")
  } else {
    unique(seurat_singlet$HTO_classification)
  }
  
  if ("HTO_classification" %in% colnames(seurat_singlet@meta.data)) {
    unexpected <- setdiff(unique(seurat_singlet$HTO_classification), expected_htos)
    if (length(unexpected) > 0) {
      cat("  NOTE: unexpected hashtag labels found and will be dropped:",
          paste(unexpected, collapse = ", "), "\n")
      keep <- seurat_singlet$HTO_classification %in% expected_htos
      seurat_singlet <- seurat_singlet[, keep]
    }
    cat("  Cells after hashtag-consistency check:", ncol(seurat_singlet), "\n")
  }
  
  if (ncol(seurat_singlet) == 0) {
    cat("  WARNING: 0 cells remain for", sample_id, "- skipping metadata assignment.\n")
    next
  }
  
  # ---- Build full metadata block ----
  hashtag_id <- if ("HTO_classification" %in% colnames(seurat_singlet@meta.data)) {
    as.character(seurat_singlet$HTO_classification)
  } else {
    rep("Unknown", ncol(seurat_singlet))
  }
  
  treatment <- unname(treatment_map[hashtag_id])
  treatment[is.na(treatment)] <- "Unknown"
  
  sample_group <- ifelse(sample_id %in% condition_a_samples, "Group_A", "Group_B")
  pair <- unname(pair_map[sample_id])
  biological_replicate <- paste0(sample_id, "_", hashtag_id)
  
  new_metadata <- data.frame(
    hashtag_id            = hashtag_id,
    treatment              = treatment,
    sample_group           = sample_group,
    pair                    = pair,
    biological_replicate  = biological_replicate,
    row.names              = colnames(seurat_singlet),
    stringsAsFactors        = FALSE
  )
  
  seurat_singlet <- AddMetaData(seurat_singlet, metadata = new_metadata)
  
  cat("  Treatment breakdown:\n")
  print(table(seurat_singlet$treatment))
  
  filtered_list[[sample_id]] <- seurat_singlet
}

# ----------------------------
# Cross-sample summary
# ----------------------------

cat("\n=============================================================================\n")
cat("FILTERING + METADATA SUMMARY\n")
cat("=============================================================================\n")

successful_samples <- names(filtered_list)
cat("Samples retained:", length(successful_samples), "/", length(sample_ids), "\n")
cat("  ", paste(successful_samples, collapse = ", "), "\n\n")

summary_df <- do.call(rbind, lapply(successful_samples, function(s) {
  obj <- filtered_list[[s]]
  data.frame(
    sample_id    = s,
    sample_group = unique(obj$sample_group),
    pair          = unique(obj$pair),
    n_cells       = ncol(obj)
  )
}))
print(summary_df)

cat("\nOverall treatment distribution across all retained samples:\n")
all_treatments <- unlist(lapply(filtered_list, function(x) x$treatment))
print(table(all_treatments))

cat("=============================================================================\n")

# ----------------------------
# Save — always to the fixed qs_dir location
# ----------------------------

out_path <- file.path(qs_dir, "filtered_list.qs2")
qs_save(filtered_list, file = out_path)
cat("\nSaved filtered + annotated Seurat object list to:\n ", out_path, "\n")

write.csv(summary_df, file.path(results_dir, "sample_filtering_summary.csv"), row.names = FALSE)
cat("Saved sample_filtering_summary.csv to:\n ", results_dir, "\n")

# =============================================================================
# STEP 6: Merge all samples, join layers (if applicable), normalize,
# find variable features
# =============================================================================

library(Seurat)
library(qs2)
library(ggplot2)

set.seed(42)

# ----------------------------
# Fixed absolute paths — identical across all steps
# ----------------------------

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

if (!dir.exists(qs_dir))      dir.create(qs_dir, recursive = TRUE)
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

# ----------------------------
# Load Step 5 output
# ----------------------------

in_path <- file.path(qs_dir, "filtered_list.qs2")
filtered_list <- qs_read(in_path)
cat("Loaded filtered + annotated Seurat object list from:\n ", in_path, "\n\n")

sample_ids <- names(filtered_list)

# ----------------------------
# Merge
# ----------------------------

cat("Merging", length(filtered_list), "samples...\n")

if (length(filtered_list) == 1) {
  seurat_merged <- filtered_list[[1]]
} else {
  seurat_merged <- merge(
    filtered_list[[1]],
    y = filtered_list[2:length(filtered_list)],
    add.cell.ids = sample_ids,
    project = "HTO_Demux_Project"
  )
  
  # JoinLayers() only applies to Seurat v5 'Assay5' objects with split
  # layers (e.g. counts.1, counts.2, ...). If the RNA assay is a classic
  # 'Assay' object (no layer splitting occurred at merge), joining is
  # unnecessary and the call would error - so check the class first.
  rna_assay <- seurat_merged[["RNA"]]
  assay_class <- class(rna_assay)[1]
  cat("RNA assay class after merge:", assay_class, "\n")
  
  if (assay_class == "Assay5") {
    n_layers <- length(Layers(seurat_merged, assay = "RNA"))
    cat("Detected", n_layers, "layers in Assay5 object.\n")
    if (n_layers > 1) {
      cat("Joining RNA layers...\n")
      seurat_merged[["RNA"]] <- JoinLayers(seurat_merged[["RNA"]])
    } else {
      cat("Only 1 layer present - no joining needed.\n")
    }
  } else {
    cat("Classic Assay object detected - layers are not split; skipping JoinLayers().\n")
  }
}

cat("Total cells after merging:", ncol(seurat_merged), "\n")
cat("Total genes:", nrow(seurat_merged), "\n\n")

# ----------------------------
# Verify metadata survived the merge
# ----------------------------

required_cols <- c("sample_id", "treatment", "sample_group", "pair",
                   "hashtag_id", "biological_replicate")
missing_cols <- required_cols[!required_cols %in% colnames(seurat_merged@meta.data)]

if (length(missing_cols) > 0) {
  stop("Metadata columns missing after merge: ", paste(missing_cols, collapse = ", "),
       ". Stopping so this can be fixed before continuing.")
}

cat("Metadata check passed. All required columns present.\n\n")

cat("Treatment distribution (post-merge):\n")
print(table(seurat_merged$treatment))
cat("\nSample group distribution:\n")
print(table(seurat_merged$sample_group))
cat("\nPair distribution:\n")
print(table(seurat_merged$pair))
cat("\nSample ID distribution:\n")
print(table(seurat_merged$sample_id))

# ----------------------------
# Normalize and find variable features
# ----------------------------

cat("\nNormalizing (log-normalization) and finding variable features...\n")

seurat_merged <- NormalizeData(seurat_merged, assay = "RNA")
seurat_merged <- FindVariableFeatures(seurat_merged, assay = "RNA", nfeatures = 2000)

top10 <- head(VariableFeatures(seurat_merged), 10)
cat("Top 10 variable features:\n")
print(top10)

# ----------------------------
# Diagnostic plot
# ----------------------------

pdf_path <- file.path(results_dir, "variable_features.pdf")
pdf(pdf_path, width = 10, height = 6)
p1 <- VariableFeaturePlot(seurat_merged)
p2 <- LabelPoints(plot = p1, points = top10, repel = TRUE)
print(p2)
dev.off()
cat("Saved variable feature plot to:\n ", pdf_path, "\n")

# ----------------------------
# Save — always to the fixed qs_dir location
# ----------------------------

out_path <- file.path(qs_dir, "seurat_merged_normalized.qs2")
qs_save(seurat_merged, file = out_path)
cat("\nSaved merged + normalized Seurat object to:\n ", out_path, "\n")

# =============================================================================
# STEP 7: Scale data and run PCA (pre-Harmony)
# Harmony (Step 8) will correct these PCA embeddings for batch effects
# across sample_id before clustering/UMAP in Step 9.
# =============================================================================

library(Seurat)
library(qs2)
library(ggplot2)

set.seed(42)

# Memory safety for large merged object (~90k cells)
options(future.globals.maxSize = 16 * 1024^3)

# ----------------------------
# Fixed absolute paths — identical across all steps
# ----------------------------

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

if (!dir.exists(qs_dir))      dir.create(qs_dir, recursive = TRUE)
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

# ----------------------------
# Load Step 6 output directly (no need to re-run Step 6)
# ----------------------------

in_path <- file.path(qs_dir, "seurat_merged_normalized.qs2")
seurat_merged <- qs_read(in_path)
cat("Loaded merged + normalized Seurat object from:\n ", in_path, "\n\n")

cat("Cells:", ncol(seurat_merged), "| Genes:", nrow(seurat_merged), "\n")
cat("Variable features available:", length(VariableFeatures(seurat_merged)), "\n\n")

# ----------------------------
# Scale (variable features only, to save memory) and run PCA
# ----------------------------

cat("Scaling data on", length(VariableFeatures(seurat_merged)), "variable features...\n")
seurat_merged <- ScaleData(seurat_merged, features = VariableFeatures(seurat_merged))

cat("Running PCA (50 PCs)...\n")
seurat_merged <- RunPCA(
  seurat_merged,
  features = VariableFeatures(seurat_merged),
  npcs = 50
)

# ----------------------------
# Diagnostic plots — pre-Harmony PCA, to visualize batch effect
# before correction (useful comparison point after Step 8 runs)
# ----------------------------

pdf_path <- file.path(results_dir, "PCA_preHarmony.pdf")
pdf(pdf_path, width = 12, height = 8)
print(DimPlot(seurat_merged, reduction = "pca", group.by = "sample_id") +
        ggtitle("PCA (pre-Harmony) - Sample ID"))
print(DimPlot(seurat_merged, reduction = "pca", group.by = "treatment") +
        ggtitle("PCA (pre-Harmony) - Treatment"))
print(DimPlot(seurat_merged, reduction = "pca", group.by = "sample_group") +
        ggtitle("PCA (pre-Harmony) - Sample Group"))
print(DimPlot(seurat_merged, reduction = "pca", group.by = "pair") +
        ggtitle("PCA (pre-Harmony) - Pair"))
print(ElbowPlot(seurat_merged, ndims = 50))
dev.off()
cat("Saved pre-Harmony PCA diagnostic plots to:\n ", pdf_path, "\n")
cat("Review the 'Sample ID' PCA plot: if samples separate into distinct\n")
cat("clusters by sample_id rather than mixing, that confirms batch effect\n")
cat("and justifies the Harmony correction in Step 8.\n\n")

# ----------------------------
# Save — always to the fixed qs_dir location
# ----------------------------

out_path <- file.path(qs_dir, "seurat_pca.qs2")
qs_save(seurat_merged, file = out_path)
cat("Saved PCA-processed Seurat object to:\n ", out_path, "\n")

# =============================================================================
# STEP 8: Harmony integration (batch correction on PCA embeddings)
#
# Grouping variable: sample_id (default)
# Rationale: each of the 8 samples (NA1-NA8) is the actual technical/
# processing unit (separate 10x lane, separate library prep). 'pair' is
# a treatment-pairing label layered on top of sample_id, not a distinct
# technical batch, so it is not the appropriate correction variable here.
#
# To override: change harmony_group_var below to "pair" and re-run.
# =============================================================================

library(Seurat)
library(harmony)
library(qs2)
library(ggplot2)

set.seed(42)

options(future.globals.maxSize = 16 * 1024^3)

# ----------------------------
# Fixed absolute paths — identical across all steps
# ----------------------------

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

if (!dir.exists(qs_dir))      dir.create(qs_dir, recursive = TRUE)
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

# ----------------------------
# Harmony grouping variable — change here if needed
# ----------------------------

harmony_group_var <- "sample_id"

# ----------------------------
# Load Step 7 output
# ----------------------------

in_path <- file.path(qs_dir, "seurat_pca.qs2")
seurat_merged <- qs_read(in_path)
cat("Loaded PCA-processed Seurat object from:\n ", in_path, "\n\n")

cat("Cells:", ncol(seurat_merged), "\n")
cat("Harmony will correct on grouping variable:", harmony_group_var, "\n")
cat("Levels present:", paste(unique(seurat_merged[[harmony_group_var]][[1]]), collapse = ", "), "\n\n")

# ----------------------------
# Run Harmony on the PCA embedding
# ----------------------------

cat("Running Harmony integration...\n")

seurat_merged <- RunHarmony(
  seurat_merged,
  group.by.vars = harmony_group_var,
  reduction.use = "pca",
  reduction.save = "harmony",
  dims.use = 1:30,
  assay.use = "RNA"
)

cat("Harmony integration complete. Embedding stored as 'harmony' reduction.\n\n")

# ----------------------------
# Diagnostic plots — post-Harmony, same grouping variables as Step 7
# for direct before/after comparison
# ----------------------------

pdf_path <- file.path(results_dir, "PCA_postHarmony.pdf")
pdf(pdf_path, width = 12, height = 8)
print(DimPlot(seurat_merged, reduction = "harmony", group.by = "sample_id") +
        ggtitle("Harmony - Sample ID"))
print(DimPlot(seurat_merged, reduction = "harmony", group.by = "treatment") +
        ggtitle("Harmony - Treatment"))
print(DimPlot(seurat_merged, reduction = "harmony", group.by = "sample_group") +
        ggtitle("Harmony - Sample Group"))
print(DimPlot(seurat_merged, reduction = "harmony", group.by = "pair") +
        ggtitle("Harmony - Pair"))
print(ElbowPlot(seurat_merged, ndims = 30, reduction = "harmony"))
dev.off()

cat("Saved post-Harmony diagnostic plots to:\n ", pdf_path, "\n")
cat("Compare 'Sample ID' panel here against PCA_preHarmony.pdf - samples\n")
cat("should now mix more evenly if batch correction was effective.\n\n")

# ----------------------------
# Save — always to the fixed qs_dir location
# ----------------------------

out_path <- file.path(qs_dir, "seurat_harmony.qs2")
qs_save(seurat_merged, file = out_path)
cat("Saved Harmony-integrated Seurat object to:\n ", out_path, "\n")

# =============================================================================
# STEP 9: Clustering and dimensionality reduction on Harmony embedding
# Uses the Harmony-corrected reduction (not raw PCA) for neighbors,
# clustering, UMAP, and t-SNE.
# =============================================================================

library(Seurat)
library(qs2)
library(ggplot2)
library(patchwork)

set.seed(42)

options(future.globals.maxSize = 16 * 1024^3)

# ----------------------------
# Fixed absolute paths — identical across all steps
# ----------------------------

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

if (!dir.exists(qs_dir))      dir.create(qs_dir, recursive = TRUE)
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

# ----------------------------
# Clustering parameters — adjust here if needed
# ----------------------------

n_dims      <- 30    # matches dims.use from Harmony (Step 8)
resolution  <- 0.8   # FindClusters resolution

# ----------------------------
# Load Step 8 output
# ----------------------------

in_path <- file.path(qs_dir, "seurat_harmony.qs2")
seurat_final <- qs_read(in_path)
cat("Loaded Harmony-integrated Seurat object from:\n ", in_path, "\n\n")

cat("Cells:", ncol(seurat_final), "\n")
cat("Using", n_dims, "Harmony dimensions, clustering resolution =", resolution, "\n\n")

# ----------------------------
# Neighbors, clustering, UMAP, t-SNE — all on 'harmony' reduction
# ----------------------------

cat("Finding neighbors (on Harmony embedding)...\n")
seurat_final <- FindNeighbors(seurat_final, reduction = "harmony", dims = 1:n_dims)

cat("Clustering (resolution =", resolution, ")...\n")
seurat_final <- FindClusters(seurat_final, resolution = resolution)

cat("Running UMAP (on Harmony embedding)...\n")
seurat_final <- RunUMAP(seurat_final, reduction = "harmony", dims = 1:n_dims)

cat("Running t-SNE (on Harmony embedding)...\n")
seurat_final <- RunTSNE(seurat_final, reduction = "harmony", dims = 1:n_dims)

cat("\nNumber of clusters found:", length(unique(seurat_final$seurat_clusters)), "\n")
cat("Cluster sizes:\n")
print(table(seurat_final$seurat_clusters))

# ----------------------------
# UMAP visualizations
# ----------------------------

pdf_path_umap <- file.path(results_dir, "UMAP_visualizations.pdf")
pdf(pdf_path_umap, width = 16, height = 12)

p1 <- DimPlot(seurat_final, reduction = "umap", label = TRUE, label.size = 6) +
  ggtitle("Clusters")
p2 <- DimPlot(seurat_final, reduction = "umap", group.by = "sample_id") +
  ggtitle("Sample ID")
p3 <- DimPlot(seurat_final, reduction = "umap", group.by = "treatment") +
  ggtitle("Treatment")
p4 <- DimPlot(seurat_final, reduction = "umap", group.by = "sample_group") +
  ggtitle("Sample Group")
print((p1 | p2) / (p3 | p4))

p5 <- DimPlot(seurat_final, reduction = "umap", group.by = "hashtag_id") +
  ggtitle("Hashtag Identity")
print(p5)

p6 <- DimPlot(seurat_final, reduction = "umap", group.by = "pair") +
  ggtitle("Paired Samples")
print(p6)

print(DimPlot(seurat_final, reduction = "umap", split.by = "treatment", ncol = 2, label = TRUE))
print(DimPlot(seurat_final, reduction = "umap", split.by = "sample_id", ncol = 4))

dev.off()
cat("\nSaved UMAP visualizations to:\n ", pdf_path_umap, "\n")

# ----------------------------
# t-SNE visualizations
# ----------------------------

pdf_path_tsne <- file.path(results_dir, "tSNE_visualizations.pdf")
pdf(pdf_path_tsne, width = 16, height = 12)

p1 <- DimPlot(seurat_final, reduction = "tsne", label = TRUE, label.size = 6) +
  ggtitle("Clusters")
p2 <- DimPlot(seurat_final, reduction = "tsne", group.by = "sample_id") +
  ggtitle("Sample ID")
p3 <- DimPlot(seurat_final, reduction = "tsne", group.by = "treatment") +
  ggtitle("Treatment")
p4 <- DimPlot(seurat_final, reduction = "tsne", group.by = "sample_group") +
  ggtitle("Sample Group")
print((p1 | p2) / (p3 | p4))

dev.off()
cat("Saved t-SNE visualizations to:\n ", pdf_path_tsne, "\n")

# ----------------------------
# Save — always to the fixed qs_dir location
# ----------------------------

out_path <- file.path(qs_dir, "seurat_clustered.qs2")
qs_save(seurat_final, file = out_path)
cat("\nSaved clustered Seurat object (with UMAP/t-SNE) to:\n ", out_path, "\n")

# =============================================================================
# STEP 10: Find cluster markers (unbiased, for annotation)
# Runs FindAllMarkers on the Harmony-clustered object, saves the full
# table plus top markers per cluster, and generates heatmap/dotplot.
# This is the evidence base for Step 11 (marker-driven annotation).
# =============================================================================

library(Seurat)
library(qs2)
library(dplyr)
library(ggplot2)

set.seed(42)

options(future.globals.maxSize = 16 * 1024^3)

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

if (!dir.exists(qs_dir))      dir.create(qs_dir, recursive = TRUE)
if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

in_path <- file.path(qs_dir, "seurat_clustered.qs2")
seurat_final <- qs_read(in_path)
cat("Loaded clustered Seurat object from:\n ", in_path, "\n\n")

Idents(seurat_final) <- "seurat_clusters"
cat("Number of clusters:", length(unique(Idents(seurat_final))), "\n")
print(table(Idents(seurat_final)))

# ----------------------------
# Unbiased marker discovery
# ----------------------------

cat("\nRunning FindAllMarkers (this can take several minutes on ~90k cells)...\n")

all_markers <- FindAllMarkers(
  seurat_final,
  only.pos = TRUE,
  min.pct = 0.25,
  logfc.threshold = 0.25
)

write.csv(all_markers, file.path(results_dir, "cluster_markers_all.csv"), row.names = FALSE)
cat("Saved full marker table to cluster_markers_all.csv\n\n")

# Top markers per cluster, ranked by avg_log2FC
top10_markers <- all_markers %>%
  group_by(cluster) %>%
  slice_max(order_by = avg_log2FC, n = 10)

top5_markers <- all_markers %>%
  group_by(cluster) %>%
  slice_max(order_by = avg_log2FC, n = 5)

write.csv(top10_markers, file.path(results_dir, "cluster_markers_top10.csv"), row.names = FALSE)
cat("Saved top-10-per-cluster table to cluster_markers_top10.csv\n\n")

cat("Top 5 markers per cluster (for quick review):\n")
print(top5_markers %>% select(cluster, gene, avg_log2FC, pct.1, pct.2, p_val_adj), n = 200)

# ----------------------------
# Heatmap and dot plot
# ----------------------------

pdf_path_heat <- file.path(results_dir, "marker_heatmap.pdf")
pdf(pdf_path_heat, width = 14, height = 12)
print(DoHeatmap(seurat_final, features = unique(top10_markers$gene)) + NoLegend())
dev.off()
cat("Saved marker heatmap to:\n ", pdf_path_heat, "\n")

pdf_path_dot <- file.path(results_dir, "marker_dotplot.pdf")
pdf(pdf_path_dot, width = 18, height = 10)
print(DotPlot(seurat_final, features = unique(top5_markers$gene)) + RotatedAxis())
dev.off()
cat("Saved marker dot plot to:\n ", pdf_path_dot, "\n")

# ----------------------------
# Save
# ----------------------------

out_path <- file.path(qs_dir, "seurat_with_markers.qs2")
qs_save(seurat_final, file = out_path)
cat("\nSaved Seurat object to:\n ", out_path, "\n")

saveRDS_path <- file.path(qs_dir, "all_markers_table.qs2")
qs_save(all_markers, file = saveRDS_path)
cat("Saved marker table object to:\n ", saveRDS_path, "\n")

# =============================================================================
# STEP 11: Score canonical immune lineage markers per cluster
#
# This builds a quantitative evidence table (mean expression + percent
# expressing per cluster) for a curated panel of canonical mouse immune
# lineage markers. Used together with Step 10's unbiased markers to make
# defensible, citable cluster annotations in Step 12 - not a guess from
# UMAP shape alone.
#
# Panel covers: T cells (CD4/CD8/naive/memory/Treg/proliferating),
# NK cells, B cells/plasma cells, myeloid (macrophage/monocyte/DC),
# granulocytes, and general proliferation.
# =============================================================================

library(Seurat)
library(qs2)
library(dplyr)
library(tidyr)
library(ggplot2)

set.seed(42)

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

in_path <- file.path(qs_dir, "seurat_with_markers.qs2")
seurat_final <- qs_read(in_path)
cat("Loaded Seurat object with markers from:\n ", in_path, "\n\n")

Idents(seurat_final) <- "seurat_clusters"

# ----------------------------
# Curated canonical marker panel (mouse gene symbols)
# Edit this list if your tissue/panel needs different markers.
# ----------------------------

lineage_markers <- list(
  "T cell (general)"        = c("Cd3e", "Cd3d", "Cd3g", "Trbc1", "Trbc2"),
  "CD4 T cell"                = c("Cd4"),
  "CD8 T cell"                = c("Cd8a", "Cd8b1"),
  "Naive T cell"              = c("Sell", "Ccr7", "Lef1", "Tcf7"),
  "Effector/Memory T cell"   = c("Ccl5", "Gzmk", "Nkg7", "Il7r"),
  "Treg"                       = c("Foxp3", "Ctla4", "Il2ra", "Ikzf2"),
  "Proliferating"             = c("Mki67", "Top2a", "Pclaf", "Birc5", "Ccnb2"),
  "NK cell"                    = c("Ncr1", "Klrb1c", "Klrd1", "Nkg7", "Prf1", "Gzma"),
  "B cell"                     = c("Cd79a", "Cd79b", "Ms4a1", "Pax5", "Ebf1", "Cd19"),
  "Plasma cell"               = c("Igha", "Ighg1", "Ighm", "Jchain", "Sdc1"),
  "Macrophage/Monocyte"      = c("Cd68", "Csf1r", "Lyz2", "Itgam", "Adgre1", "Mpeg1"),
  "Dendritic cell"            = c("Cd74", "H2-Ab1", "H2-Aa", "Flt3", "Itgax"),
  "Granulocyte/Neutrophil"   = c("S100a8", "S100a9", "Ly6g", "Mpo"),
  "Epithelial/Non-immune"    = c("Epcam", "Krt8", "Krt18", "Pecam1")
)

all_genes <- unique(unlist(lineage_markers))
present_genes <- all_genes[all_genes %in% rownames(seurat_final)]
missing_genes <- setdiff(all_genes, present_genes)

if (length(missing_genes) > 0) {
  cat("NOTE: the following panel genes were not found in this dataset and will be skipped:\n")
  cat(" ", paste(missing_genes, collapse = ", "), "\n\n")
}

# ----------------------------
# Mean expression + percent expressing per cluster, per gene
# ----------------------------

cat("Computing per-cluster mean expression and percent expressing for",
    length(present_genes), "panel genes...\n\n")

avg_exp <- AverageExpression(
  seurat_final,
  features = present_genes,
  group.by = "seurat_clusters",
  assays = "RNA",
  slot = "data"
)$RNA

pct_exp_matrix <- sapply(present_genes, function(g) {
  expr <- FetchData(seurat_final, vars = g)[[1]]
  clusters <- seurat_final$seurat_clusters
  tapply(expr, clusters, function(x) mean(x > 0) * 100)
})
pct_exp_matrix <- t(pct_exp_matrix)

# ----------------------------
# Build a long-format score table: cluster x lineage, using mean of
# scaled average expression across each lineage's marker genes
# ----------------------------

avg_exp_scaled <- t(scale(t(avg_exp)))  # z-score each gene across clusters

lineage_scores <- data.frame(cluster = colnames(avg_exp_scaled))

for (lineage in names(lineage_markers)) {
  genes_here <- intersect(lineage_markers[[lineage]], rownames(avg_exp_scaled))
  if (length(genes_here) == 0) {
    lineage_scores[[lineage]] <- NA
    next
  }
  if (length(genes_here) == 1) {
    scores <- avg_exp_scaled[genes_here, ]
  } else {
    scores <- colMeans(avg_exp_scaled[genes_here, , drop = FALSE])
  }
  lineage_scores[[lineage]] <- as.numeric(scores)
}

cat("Lineage score matrix (z-scored mean expression per cluster):\n")
print(lineage_scores)

# Identify the top-scoring lineage per cluster (candidate call)
lineage_only <- lineage_scores[, -1, drop = FALSE]
top_lineage <- apply(lineage_only, 1, function(row) {
  if (all(is.na(row))) return(NA)
  names(row)[which.max(row)]
})

lineage_scores$top_candidate_lineage <- top_lineage

cat("\nTop candidate lineage per cluster (highest z-scored panel score):\n")
print(lineage_scores[, c("cluster", "top_candidate_lineage")])

write.csv(lineage_scores, file.path(results_dir, "cluster_lineage_scores.csv"), row.names = FALSE)
cat("\nSaved lineage score table to cluster_lineage_scores.csv\n")

# ----------------------------
# Dot plot of the full curated panel, grouped by cluster, for visual review
# ----------------------------

pdf_path <- file.path(results_dir, "lineage_marker_dotplot.pdf")
pdf(pdf_path, width = 20, height = 10)
print(DotPlot(seurat_final, features = present_genes, group.by = "seurat_clusters") +
        RotatedAxis() +
        ggtitle("Canonical lineage marker panel by cluster"))
dev.off()
cat("Saved lineage marker dot plot to:\n ", pdf_path, "\n")

# ----------------------------
# Save
# ----------------------------

out_path <- file.path(qs_dir, "lineage_scores.qs2")
qs_save(lineage_scores, file = out_path)
cat("\nSaved lineage score object to:\n ", out_path, "\n")

# =============================================================================
# STEP 12: Finalize cluster annotation
#
# Every label below is justified by unbiased FindAllMarkers() top genes
# (Step 10), cross-checked against the curated lineage panel z-scores
# (Step 11) where unambiguous. Ambiguous panel calls (margin < 0.5
# between top two lineage scores) were resolved using the unbiased
# markers directly rather than trusting the panel average.
#
# Two clusters (20, 34) are flagged as non-immune contaminating tissue
# (exocrine pancreas, stroma/endothelium) rather than forced into an
# immune cell type - this matters for a BDC2.5/aCD3 pancreatic
# infiltrate model where surrounding tissue is expected in dissociation.
# =============================================================================

library(Seurat)
library(qs2)
library(ggplot2)
library(dplyr)

set.seed(42)

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

in_path <- file.path(qs_dir, "seurat_with_markers.qs2")
seurat_final <- qs_read(in_path)
cat("Loaded Seurat object from:\n ", in_path, "\n\n")

# ----------------------------
# Cluster -> cell type annotation map
# Deciding evidence noted per cluster (from cluster_markers_top10.csv)
# ----------------------------

cluster_annotations <- c(
  "0"  = "Naive/CM CD4 T cell",
  "1"  = "Effector CD8 T cell",
  "2"  = "Treg",
  "3"  = "Activated CD4 T cell",
  "4"  = "Naive T cell",
  "5"  = "B cell",
  "6"  = "NK/NKT cell",
  "7"  = "ILC2",
  "8"  = "Activated/Exhausted CD4 T cell",
  "9"  = "CD4 T helper",
  "10" = "Low-quality/stressed T cell",
  "11" = "NK cell (Klrb1b+ subset)",
  "12" = "Proliferating lymphocyte",
  "13" = "Interferon-stimulated immune cell",
  "14" = "Gamma-delta T cell",
  "15" = "ILC3/Th17-like",
  "16" = "Plasma cell",
  "17" = "NK cell (Gzma+ cytotoxic)",
  "18" = "Dendritic cell",
  "19" = "Naive CD8 T cell",
  "20" = "Exocrine pancreas (contaminant)",
  "21" = "Macrophage/Monocyte",
  "22" = "NK cell (Klrb1b+/Xcl1+)",
  "23" = "Gamma-delta T17 cell",
  "24" = "Th17-like CD4 T cell",
  "25" = "Plasmacytoid dendritic cell",
  "26" = "NK/NKT cell subset",
  "27" = "B cell",
  "28" = "ILC2",
  "29" = "Gamma-delta T17 cell",
  "30" = "Dendritic cell",
  "31" = "Mature/migratory DC",
  "32" = "ILC3-like",
  "33" = "B cell (small cluster)",
  "34" = "Stromal/endothelial (contaminant)"
)

# ----------------------------
# Apply annotation as new metadata column
# FIX: unname() strips the lookup-table names (which are cluster IDs,
# e.g. "0","1"...) so the assigned vector aligns purely by position with
# seurat_final's cells. Without unname(), Seurat's $<- tries to match
# those leftover names against cell barcodes and finds no overlap.
# ----------------------------

seurat_final$cell_type <- unname(cluster_annotations[as.character(seurat_final$seurat_clusters)])

cat("Cell type assignment complete.\n\n")
cat("Cell type distribution:\n")
print(table(seurat_final$cell_type))

seurat_final$is_contaminant <- seurat_final$cell_type %in%
  c("Exocrine pancreas (contaminant)", "Stromal/endothelial (contaminant)")

cat("\nContaminant cell counts:\n")
print(table(seurat_final$is_contaminant))

# ----------------------------
# Broader lineage grouping (collapses subtypes for high-level plots)
# ----------------------------

lineage_group_map <- c(
  "Naive/CM CD4 T cell"                = "CD4 T cell",
  "Activated CD4 T cell"               = "CD4 T cell",
  "Activated/Exhausted CD4 T cell"     = "CD4 T cell",
  "CD4 T helper"                        = "CD4 T cell",
  "Th17-like CD4 T cell"                = "CD4 T cell",
  "Naive T cell"                         = "T cell (other)",
  "Treg"                                  = "Treg",
  "Effector CD8 T cell"                 = "CD8 T cell",
  "Naive CD8 T cell"                    = "CD8 T cell",
  "Gamma-delta T cell"                  = "Gamma-delta T cell",
  "Gamma-delta T17 cell"                = "Gamma-delta T cell",
  "ILC2"                                  = "ILC",
  "ILC3/Th17-like"                       = "ILC",
  "ILC3-like"                            = "ILC",
  "NK/NKT cell"                          = "NK cell",
  "NK cell (Klrb1b+ subset)"            = "NK cell",
  "NK cell (Gzma+ cytotoxic)"           = "NK cell",
  "NK cell (Klrb1b+/Xcl1+)"             = "NK cell",
  "NK/NKT cell subset"                  = "NK cell",
  "B cell"                                = "B cell",
  "B cell (small cluster)"              = "B cell",
  "Plasma cell"                          = "Plasma cell",
  "Macrophage/Monocyte"                 = "Myeloid",
  "Dendritic cell"                       = "Myeloid",
  "Mature/migratory DC"                 = "Myeloid",
  "Plasmacytoid dendritic cell"         = "Myeloid",
  "Proliferating lymphocyte"            = "Proliferating",
  "Interferon-stimulated immune cell"   = "Other immune",
  "Low-quality/stressed T cell"         = "Low quality",
  "Exocrine pancreas (contaminant)"     = "Non-immune contaminant",
  "Stromal/endothelial (contaminant)"   = "Non-immune contaminant"
)

seurat_final$lineage_group <- unname(lineage_group_map[seurat_final$cell_type])

cat("\nBroad lineage group distribution:\n")
print(table(seurat_final$lineage_group))

# ----------------------------
# Diagnostic plots
# ----------------------------

pdf_path <- file.path(results_dir, "UMAP_annotated.pdf")
pdf(pdf_path, width = 16, height = 12)

p1 <- DimPlot(seurat_final, reduction = "umap", group.by = "cell_type",
              label = TRUE, repel = TRUE, label.size = 3) +
  ggtitle("Detailed cell type annotation") + NoLegend()
print(p1)

p2 <- DimPlot(seurat_final, reduction = "umap", group.by = "lineage_group",
              label = TRUE, repel = TRUE, label.size = 4) +
  ggtitle("Broad lineage grouping")
print(p2)

p3 <- DimPlot(seurat_final, reduction = "umap", group.by = "is_contaminant") +
  ggtitle("Contaminant (non-immune) cells flagged")
print(p3)

dev.off()
cat("\nSaved annotated UMAP plots to:\n ", pdf_path, "\n")

# ----------------------------
# Save annotation summary table
# ----------------------------

annotation_summary <- data.frame(
  cluster = names(cluster_annotations),
  cell_type = unname(cluster_annotations),
  lineage_group = unname(lineage_group_map[cluster_annotations]),
  n_cells = as.numeric(table(seurat_final$seurat_clusters)[names(cluster_annotations)])
)
write.csv(annotation_summary, file.path(results_dir, "cluster_annotation_final.csv"), row.names = FALSE)
cat("Saved final annotation table to cluster_annotation_final.csv\n\n")

cat("NOTE: clusters 20 and 34 are flagged as non-immune contaminant tissue\n")
cat("(exocrine pancreas and stroma/endothelium respectively), consistent\n")
cat("with dissociation of pancreas-infiltrating immune cells in a\n")
cat("BDC2.5/aCD3 model. Consider excluding these from downstream immune\n")
cat("cell composition and DE analyses (Step 13+) unless tissue-level\n")
cat("signal is of specific interest.\n\n")

# ----------------------------
# Save
# ----------------------------

out_path <- file.path(qs_dir, "seurat_annotated.qs2")
qs_save(seurat_final, file = out_path)
cat("Saved fully annotated Seurat object to:\n ", out_path, "\n")

# =============================================================================
# STEP 12b: UMAP with custom "Nature-style" matte color palette
#
# Muted, desaturated, high-contrast-but-not-garish palette in the style
# common to Nature/Cell/Science figures - avoids default ggplot neon
# hues. Colors are manually curated and grouped so visually similar
# lineages (e.g. NK subsets, T subsets) get related but distinguishable
# shades.
# =============================================================================

library(Seurat)
library(qs2)
library(ggplot2)

set.seed(42)

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

in_path <- file.path(qs_dir, "seurat_annotated.qs2")
seurat_final <- qs_read(in_path)
cat("Loaded annotated Seurat object from:\n ", in_path, "\n\n")

# ----------------------------
# Custom matte / muted "Nature-style" palette
# One color per detailed cell_type. Edit hex codes freely below.
# ----------------------------

nature_palette <- c(
  "Naive/CM CD4 T cell"                 = "#4C6E8C",  # muted steel blue
  "Activated CD4 T cell"                = "#C97B63",  # muted terracotta
  "Activated/Exhausted CD4 T cell"      = "#8C5E58",  # muted brick
  "CD4 T helper"                         = "#7A9E7E",  # muted sage
  "Th17-like CD4 T cell"                 = "#A6785E",  # muted clay
  "Naive T cell"                          = "#8FA6B8",  # dusty blue
  "Treg"                                   = "#B85C5C",  # muted red
  "Effector CD8 T cell"                  = "#3E5C76",  # deep slate blue
  "Naive CD8 T cell"                     = "#729EA1",  # muted teal
  "Gamma-delta T cell"                   = "#6B8E7F",  # deep sage
  "Gamma-delta T17 cell"                 = "#8FAF8A",  # soft moss
  "ILC2"                                   = "#D8A657",  # muted mustard
  "ILC3/Th17-like"                        = "#C8985E",  # muted amber
  "ILC3-like"                             = "#E0C08E",  # pale gold
  "NK/NKT cell"                           = "#7D5A8C",  # muted plum
  "NK cell (Klrb1b+ subset)"             = "#9C7FA8",  # dusty lavender
  "NK cell (Gzma+ cytotoxic)"            = "#5E4370",  # deep plum
  "NK cell (Klrb1b+/Xcl1+)"              = "#B49BC0",  # pale lilac
  "NK/NKT cell subset"                   = "#8A6A9C",  # medium plum
  "B cell"                                 = "#4E7C59",  # forest green
  "B cell (small cluster)"               = "#79A084",  # muted mint
  "Plasma cell"                           = "#D66C87",  # muted rose
  "Macrophage/Monocyte"                  = "#B08968",  # muted tan
  "Dendritic cell"                        = "#8C6D46",  # muted bronze
  "Mature/migratory DC"                  = "#A9855F",  # soft ochre
  "Plasmacytoid dendritic cell"          = "#C4A26A",  # pale bronze
  "Proliferating lymphocyte"             = "#5C5C5C",  # neutral grey
  "Interferon-stimulated immune cell"    = "#9A9A5C",  # muted olive
  "Low-quality/stressed T cell"          = "#B0B0B0",  # light grey
  "Exocrine pancreas (contaminant)"      = "#D9D9D9",  # very light grey
  "Stromal/endothelial (contaminant)"    = "#C9C2B4"   # warm light grey
)

# Verify every cell_type in the data has a color assigned
missing_colors <- setdiff(unique(seurat_final$cell_type), names(nature_palette))
if (length(missing_colors) > 0) {
  cat("WARNING: no color defined for these cell types - they will appear grey:\n")
  print(missing_colors)
}

# ----------------------------
# Custom matte theme (light background, thin axis lines, no gridlines)
# ----------------------------

theme_nature_matte <- theme_minimal(base_size = 13) +
  theme(
    panel.grid = element_blank(),
    axis.line = element_line(color = "grey30", linewidth = 0.4),
    axis.ticks = element_line(color = "grey30", linewidth = 0.3),
    plot.title = element_text(face = "bold", size = 15, hjust = 0),
    legend.title = element_blank(),
    legend.key.size = unit(0.4, "cm"),
    legend.text = element_text(size = 8),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

# ----------------------------
# Plot: detailed cell type, matte styled, no in-plot labels (legend only)
# ----------------------------

p_detailed <- DimPlot(
  seurat_final,
  reduction = "umap",
  group.by = "cell_type",
  pt.size = 0.3,
  raster = FALSE
) +
  scale_color_manual(values = nature_palette) +
  theme_nature_matte +
  ggtitle("Cell type annotation") +
  guides(color = guide_legend(override.aes = list(size = 3), ncol = 1))

pdf_path <- file.path(results_dir, "UMAP_nature_style.pdf")
pdf(pdf_path, width = 13, height = 9)
print(p_detailed)
dev.off()
cat("Saved matte-styled UMAP (legend only) to:\n ", pdf_path, "\n")

# ----------------------------
# Plot: same palette, with direct in-plot labels instead of legend
# ----------------------------

p_labeled <- DimPlot(
  seurat_final,
  reduction = "umap",
  group.by = "cell_type",
  pt.size = 0.3,
  label = TRUE,
  label.size = 3,
  repel = TRUE,
  raster = FALSE
) +
  scale_color_manual(values = nature_palette) +
  theme_nature_matte +
  ggtitle("Cell type annotation (labeled)") +
  NoLegend()

pdf_path_labeled <- file.path(results_dir, "UMAP_nature_style_labeled.pdf")
pdf(pdf_path_labeled, width = 12, height = 10)
print(p_labeled)
dev.off()
cat("Saved matte-styled UMAP (in-plot labels) to:\n ", pdf_path_labeled, "\n")

# ----------------------------
# Plot: broad lineage_group version, same matte aesthetic, fewer colors
# ----------------------------

lineage_palette <- c(
  "CD4 T cell"               = "#4C6E8C",
  "T cell (other)"           = "#8FA6B8",
  "Treg"                       = "#B85C5C",
  "CD8 T cell"                = "#3E5C76",
  "Gamma-delta T cell"        = "#6B8E7F",
  "ILC"                        = "#D8A657",
  "NK cell"                    = "#7D5A8C",
  "B cell"                     = "#4E7C59",
  "Plasma cell"               = "#D66C87",
  "Myeloid"                    = "#B08968",
  "Proliferating"             = "#5C5C5C",
  "Other immune"              = "#9A9A5C",
  "Low quality"                = "#B0B0B0",
  "Non-immune contaminant"    = "#D9D9D9"
)

p_lineage <- DimPlot(
  seurat_final,
  reduction = "umap",
  group.by = "lineage_group",
  pt.size = 0.3,
  raster = FALSE
) +
  scale_color_manual(values = lineage_palette) +
  theme_nature_matte +
  ggtitle("Broad lineage grouping")

pdf_path_lineage <- file.path(results_dir, "UMAP_nature_style_lineage.pdf")
pdf(pdf_path_lineage, width = 11, height = 8)
print(p_lineage)
dev.off()
cat("Saved matte-styled broad lineage UMAP to:\n ", pdf_path_lineage, "\n")

cat("\nAll three style variants saved. Edit hex codes in nature_palette or\n")
cat("lineage_palette above and re-run to adjust colors.\n")

# =============================================================================
# STEP 14: Differential gene expression - all pairwise treatment
# comparisons, run separately at two granularities:
#   (A) lineage_group   (~14 broad categories)
#   (B) cell_type        (~30 detailed categories)
#
# 4 treatments -> C(4,2) = 6 pairwise comparisons per group
# avg_log2FC is Seurat's log2 fold change; an ACTUAL (linear) fold
# change is added as its own column: actual_FC = 2^avg_log2FC
# =============================================================================

library(Seurat)
library(qs2)
library(dplyr)

set.seed(42)

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
qs_dir       <- file.path(analysis_dir, "qsfiles")
results_dir  <- file.path(analysis_dir, "results")

dge_base <- file.path(analysis_dir, "DGE")
dir.create(dge_base, showWarnings = FALSE, recursive = TRUE)

in_path <- file.path(qs_dir, "seurat_annotated.qs2")
seurat_final <- qs_read(in_path)
cat("Loaded annotated Seurat object from:\n ", in_path, "\n\n")

# Exclude non-immune contaminant clusters from DGE
n_before <- ncol(seurat_final)
seurat_final <- subset(seurat_final, subset = is_contaminant == FALSE)
cat("Excluded contaminant clusters. Cells before:", n_before,
    "| after:", ncol(seurat_final), "\n\n")

treatments <- c("Untreated", "aCD3", "aCD3_BDC2.5", "aCD3_Polyclonal")

# All pairwise combinations (order fixed: ident.1 vs ident.2)
treatment_pairs <- combn(treatments, 2, simplify = FALSE)
cat("Pairwise treatment comparisons (", length(treatment_pairs), "total):\n")
for (p in treatment_pairs) cat("  ", p[1], "vs", p[2], "\n")
cat("\n")

# ----------------------------
# Generic function: run all pairwise DGE for a given grouping variable
# ----------------------------

run_pairwise_dge <- function(seurat_obj, group_var, output_dir) {
  
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  groups <- unique(seurat_obj@meta.data[[group_var]])
  groups <- groups[!is.na(groups)]
  
  cat("=============================================================================\n")
  cat("Running DGE grouped by:", group_var, "(", length(groups), "categories )\n")
  cat("=============================================================================\n\n")
  
  composite_var <- paste0(group_var, "_treatment")
  seurat_obj@meta.data[[composite_var]] <- paste(
    seurat_obj@meta.data[[group_var]],
    seurat_obj$treatment,
    sep = "_"
  )
  
  Idents(seurat_obj) <- composite_var
  composite_levels <- unique(Idents(seurat_obj))
  
  summary_log <- data.frame(
    group = character(), comparison = character(),
    n_ident1 = integer(), n_ident2 = integer(),
    n_degs_sig = integer(), status = character(),
    stringsAsFactors = FALSE
  )
  
  for (grp in groups) {
    
    for (pair in treatment_pairs) {
      
      treat1 <- pair[1]  # ident.1
      treat2 <- pair[2]  # ident.2
      
      id1 <- paste(grp, treat1, sep = "_")
      id2 <- paste(grp, treat2, sep = "_")
      
      comp_name <- paste(grp, treat1, "vs", treat2, sep = "_")
      comp_name <- gsub("[/ ]", "_", comp_name)  # filesystem-safe
      
      if (!(id1 %in% composite_levels) || !(id2 %in% composite_levels)) {
        cat("SKIP:", comp_name, "- one or both groups absent\n")
        summary_log <- rbind(summary_log, data.frame(
          group = grp, comparison = comp_name,
          n_ident1 = NA, n_ident2 = NA, n_degs_sig = NA,
          status = "skipped_absent"
        ))
        next
      }
      
      n1 <- sum(Idents(seurat_obj) == id1)
      n2 <- sum(Idents(seurat_obj) == id2)
      
      if (n1 < 10 || n2 < 10) {
        cat("SKIP:", comp_name, "- too few cells (n1=", n1, ", n2=", n2, ")\n")
        summary_log <- rbind(summary_log, data.frame(
          group = grp, comparison = comp_name,
          n_ident1 = n1, n_ident2 = n2, n_degs_sig = NA,
          status = "skipped_low_n"
        ))
        next
      }
      
      cat("Testing:", comp_name, "(n1=", n1, ", n2=", n2, ")...\n")
      
      result <- tryCatch({
        FindMarkers(
          object = seurat_obj,
          ident.1 = id1,
          ident.2 = id2,
          test.use = "wilcox",
          min.pct = 0.1,
          logfc.threshold = 0.137504,   # ~10% change on log2 scale
          pseudocount.use = 1,
          assay = "RNA",
          only.pos = FALSE
        )
      }, error = function(e) {
        cat("  ERROR:", e$message, "\n")
        NULL
      })
      
      if (!is.null(result) && nrow(result) > 0) {
        
        result$gene <- rownames(result)
        result$comparison <- comp_name
        result$group <- grp
        result$treatment_1 <- treat1
        result$treatment_2 <- treat2
        
        # ACTUAL (linear) fold change, separate from Seurat's log2FC
        result$actual_FC <- 2^result$avg_log2FC
        
        result <- result %>%
          select(gene, p_val, avg_log2FC, actual_FC, pct.1, pct.2,
                 p_val_adj, comparison, group, treatment_1, treatment_2)
        
        n_sig <- sum(result$p_val_adj < 0.05, na.rm = TRUE)
        
        filename <- file.path(output_dir, paste0(comp_name, "_results.csv"))
        write.csv(result, file = filename, row.names = FALSE)
        
        cat("  Saved", nrow(result), "genes tested,", n_sig, "significant (padj<0.05)\n")
        
        summary_log <- rbind(summary_log, data.frame(
          group = grp, comparison = comp_name,
          n_ident1 = n1, n_ident2 = n2, n_degs_sig = n_sig,
          status = "success"
        ))
        
      } else {
        cat("  No results returned (0 genes passed thresholds).\n")
        summary_log <- rbind(summary_log, data.frame(
          group = grp, comparison = comp_name,
          n_ident1 = n1, n_ident2 = n2, n_degs_sig = 0,
          status = "no_results"
        ))
      }
    }
  }
  
  write.csv(summary_log, file.path(output_dir, "_DGE_run_summary.csv"), row.names = FALSE)
  cat("\nSaved run summary to:\n ", file.path(output_dir, "_DGE_run_summary.csv"), "\n\n")
  
  return(summary_log)
}

# ----------------------------
# (A) Broad lineage_group level
# ----------------------------

lineage_output_dir <- file.path(dge_base, "by_lineage_group")
lineage_summary <- run_pairwise_dge(seurat_final, "lineage_group", lineage_output_dir)

# ----------------------------
# (B) Detailed cell_type level
# ----------------------------

celltype_output_dir <- file.path(dge_base, "by_cell_type")
celltype_summary <- run_pairwise_dge(seurat_final, "cell_type", celltype_output_dir)

# ----------------------------
# Combined overview
# ----------------------------

cat("=============================================================================\n")
cat("DGE COMPLETE - OVERVIEW\n")
cat("=============================================================================\n")
cat("Lineage-level: ", sum(lineage_summary$status == "success"), "successful comparisons,",
    sum(lineage_summary$status != "success"), "skipped/failed\n")
cat("Cell-type-level:", sum(celltype_summary$status == "success"), "successful comparisons,",
    sum(celltype_summary$status != "success"), "skipped/failed\n")
cat("\nAll DGE CSVs saved under:\n ", dge_base, "\n")
cat("=============================================================================\n")

out_path <- file.path(qs_dir, "seurat_dge_ready.qs2")
qs_save(seurat_final, file = out_path)
cat("\nSaved (contaminant-excluded) Seurat object to:\n ", out_path, "\n")

# =============================================================================
# STEP 15: Over-representation analysis (ORA) via gprofiler2::gost()
# Mouse organism ("mmusculus"). Runs on BOTH DGE output sets:
#   (A) by_lineage_group
#   (B) by_cell_type
# For each comparison CSV: split into UP / DOWN gene sets (padj < 0.05),
# run GO enrichment separately, save to parallel UP/DOWN folder trees.
#
# NOTE: gost() queries the g:Profiler web API (biit.cs.ut.ee) and
# requires internet access. Each call is wrapped in tryCatch so one
# network failure or empty gene list does not halt the batch.
# =============================================================================

if (!requireNamespace("gprofiler2", quietly = TRUE)) {
  install.packages("gprofiler2")
}

library(gprofiler2)
library(dplyr)
library(readr)

analysis_dir <- "C:/Users/apocl/UF Dropbox/Fahd Qadir/QLab_unrestrcited/Qlab shared to ABlab/Emerson/analysis"
dge_base     <- file.path(analysis_dir, "DGE")
ora_base     <- file.path(analysis_dir, "ORA")
dir.create(ora_base, showWarnings = FALSE, recursive = TRUE)

dge_folders <- list(
  by_lineage_group = file.path(dge_base, "by_lineage_group"),
  by_cell_type      = file.path(dge_base, "by_cell_type")
)

drop_cols <- c("parents", "source_order", "effective_domain_size", "query",
               "precision", "recall", "evidence_codes")

# ----------------------------
# Generic ORA runner for one folder of DGE result CSVs
# ----------------------------

run_ora_on_folder <- function(input_dir, output_up, output_down) {
  
  dir.create(output_up, showWarnings = FALSE, recursive = TRUE)
  dir.create(output_down, showWarnings = FALSE, recursive = TRUE)
  
  dge_files <- list.files(input_dir, pattern = "_results\\.csv$", full.names = TRUE)
  cat("Found", length(dge_files), "DGE result files in:\n ", input_dir, "\n\n")
  
  ora_log <- data.frame(
    file = character(), n_up = integer(), n_down = integer(),
    up_terms = integer(), down_terms = integer(), status = character(),
    stringsAsFactors = FALSE
  )
  
  for (file in dge_files) {
    
    fname <- basename(file)
    cat("Processing:", fname, "...\n")
    
    dat <- tryCatch(read.csv(file), error = function(e) NULL)
    
    if (is.null(dat) || nrow(dat) == 0) {
      cat("  Skipping - could not read or empty file.\n")
      ora_log <- rbind(ora_log, data.frame(
        file = fname, n_up = NA, n_down = NA,
        up_terms = NA, down_terms = NA, status = "read_error"
      ))
      next
    }
    
    if (!"avg_log2FC" %in% names(dat)) {
      logfc_col <- grep("log2FC", names(dat), value = TRUE)
      if (length(logfc_col) == 1) names(dat)[names(dat) == logfc_col] <- "avg_log2FC"
    }
    if (!"p_val_adj" %in% names(dat)) {
      adjp_col <- grep("adj", names(dat), value = TRUE)
      if (length(adjp_col) == 1) names(dat)[names(dat) == adjp_col] <- "p_val_adj"
    }
    if (!"gene" %in% names(dat)) {
      cat("  Skipping - no 'gene' column found.\n")
      next
    }
    
    up   <- dplyr::filter(dat, p_val_adj < 0.05 & avg_log2FC > 0)$gene
    down <- dplyr::filter(dat, p_val_adj < 0.05 & avg_log2FC < 0)$gene
    
    n_up_terms <- NA
    n_down_terms <- NA
    
    # ---- UP-regulated ----
    if (length(up) > 0) {
      go_up <- tryCatch({
        gost(up, organism = "mmusculus", significant = TRUE, user_threshold = 0.05,
             correction_method = "fdr", domain_scope = "annotated",
             sources = "GO", evcodes = TRUE)
      }, error = function(e) {
        cat("  gost() ERROR (UP):", e$message, "\n")
        NULL
      })
      
      if (!is.null(go_up) && !is.null(go_up$result) && nrow(go_up$result) > 0) {
        go_up_res <- as.data.frame(go_up$result)
        if ("p_value" %in% names(go_up_res)) {
          names(go_up_res)[names(go_up_res) == "p_value"] <- "hypergeometric FDR"
        }
        go_up_res <- dplyr::select(go_up_res, -dplyr::any_of(drop_cols))
        write.csv(go_up_res, file.path(output_up, fname), row.names = FALSE)
        n_up_terms <- nrow(go_up_res)
        cat("  UP:", length(up), "genes ->", n_up_terms, "enriched GO terms\n")
      } else {
        cat("  UP:", length(up), "genes -> 0 significant GO terms\n")
        n_up_terms <- 0
      }
    } else {
      cat("  UP: 0 genes passed threshold - skipping gost()\n")
    }
    
    # ---- DOWN-regulated ----
    if (length(down) > 0) {
      go_down <- tryCatch({
        gost(down, organism = "mmusculus", significant = TRUE, user_threshold = 0.05,
             correction_method = "fdr", domain_scope = "annotated",
             sources = "GO", evcodes = TRUE)
      }, error = function(e) {
        cat("  gost() ERROR (DOWN):", e$message, "\n")
        NULL
      })
      
      if (!is.null(go_down) && !is.null(go_down$result) && nrow(go_down$result) > 0) {
        go_down_res <- as.data.frame(go_down$result)
        if ("p_value" %in% names(go_down_res)) {
          names(go_down_res)[names(go_down_res) == "p_value"] <- "hypergeometric FDR"
        }
        go_down_res <- dplyr::select(go_down_res, -dplyr::any_of(drop_cols))
        write.csv(go_down_res, file.path(output_down, fname), row.names = FALSE)
        n_down_terms <- nrow(go_down_res)
        cat("  DOWN:", length(down), "genes ->", n_down_terms, "enriched GO terms\n")
      } else {
        cat("  DOWN:", length(down), "genes -> 0 significant GO terms\n")
        n_down_terms <- 0
      }
    } else {
      cat("  DOWN: 0 genes passed threshold - skipping gost()\n")
    }
    
    ora_log <- rbind(ora_log, data.frame(
      file = fname, n_up = length(up), n_down = length(down),
      up_terms = n_up_terms, down_terms = n_down_terms, status = "processed"
    ))
    
    cat("\n")
  }
  
  write.csv(ora_log, file.path(dirname(output_up), "_ORA_run_summary.csv"), row.names = FALSE)
  return(ora_log)
}

# ----------------------------
# Run ORA for both granularities
# ----------------------------

all_logs <- list()

for (type in names(dge_folders)) {
  
  cat("=============================================================================\n")
  cat("ORA for:", type, "\n")
  cat("=============================================================================\n\n")
  
  input_dir   <- dge_folders[[type]]
  output_up   <- file.path(ora_base, type, "UP")
  output_down <- file.path(ora_base, type, "DOWN")
  
  all_logs[[type]] <- run_ora_on_folder(input_dir, output_up, output_down)
}

cat("=============================================================================\n")
cat("ORA COMPLETE FOR ALL DGE FOLDERS\n")
cat("=============================================================================\n")
for (type in names(all_logs)) {
  log <- all_logs[[type]]
  cat(type, ": ", nrow(log), "files processed,",
      sum(log$up_terms > 0, na.rm = TRUE), "with UP enrichment,",
      sum(log$down_terms > 0, na.rm = TRUE), "with DOWN enrichment\n")
}
cat("\nAll ORA results saved under:\n ", ora_base, "\n")
cat("=============================================================================\n")
