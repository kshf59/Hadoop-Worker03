#
# build_report.R
#
# Copyright (C) 2017 by RStudio, Inc.
#
local({
  # Prefer to use Sys.getenv("USER") here, but at the time of this writing
  # rsandbox doesn't set $USER, so it's always root
  if (identical(.Platform$OS.type, "unix") && identical(system("whoami", intern = TRUE), "root")) {
    stop("Attempted to run report as ", Sys.getenv("USER"))
  }

  # Read config directives from stdin and put them in the environment.
  fd = file('stdin')
  d <- read.dcf(fd)

  config <- as.list(structure(
    as.vector(d),
    names = colnames(d)
  ))

  # Verify the config structure arriving over STDIN.
  expectedFields <- c(
      "ConnectDir",
      "InstalledRVersion",
      "BundleRVersion",
      "RmdFile",
      "OutputDir",
      "HasParameters"
  )

  missingFields <- setdiff(expectedFields, names(config))
  unexpectedFields <- setdiff(names(config), expectedFields)
  if (length(missingFields)!=0 || length(unexpectedFields)!=0) {
    fmt <- "Unexpected configuration; missing fields: %s; unexpected fields: %s"
    stop(sprintf(fmt,
                 paste0(missingFields, collapse=", "),
                 paste0(unexpectedFields, collapse=", ")))
  }

  MIN_R_VERSION <- "2.15.1"
  MIN_RMARKDOWN_VERSION <- "0.1.90"
  MIN_KNITR_VERSION <- "1.5.32"

  source(file = file.path(config$ConnectDir, "R", "connect.R"), local = TRUE)

  connect$enforceMinimumRVersion(MIN_R_VERSION)
  connect$enforceInstalledRVersion(config$InstalledRVersion)
  connect$enforceAssumedRVersion(config$BundleRVersion)
  connect$enforcePackratHealth()

  connect$configureAppLibDir(dirname(config$RmdFile))

  packages <- c("rmarkdown", "knitr")
  versions <- connect$getVersions(packages)

  connect$printEnvironment()
  connect$printVersions(packages, versions)
  
  connect$enforcePackageVersion("rmarkdown", MIN_RMARKDOWN_VERSION, versions$rmarkdown)
  connect$enforceDependentPackageVersion("knitr", MIN_KNITR_VERSION, versions$knitr, "rmarkdown")

  connect$addPandocToPath()
  connect$configureBrowseURL()
  connect$fixupCrossPackageReferences()

  output_options <- list()
  output_format <- rmarkdown::default_output_format(config$RmdFile)

  ## TODO: Is self-contained acceptable for both serving and attaching?
  ## We will likely need to generate multiple versions of the report.
  if ("self_contained" %in% names(output_format$options)) {
    output_options$self_contained = TRUE
  }
  ## If we build documents that are not self-contained, we should ask
  ## RMarkdown to copy in resources rather than using
  ## find_external_resources and writing that logic ourselves.
  ##
  ## if ("self_contained" %in% names(format$options)) {
  ##   output_options$self_contained = FALSE
  ## }
  ## if ("copy_resources" %in% names(format$options)) {
  ##   output_options$copy_resources = TRUE
  ## }

  render_args <- list(
      input = config$RmdFile,
      output_dir = config$OutputDir,
      intermediates_dir = tempdir(),
      envir = new.env(),
      output_options = output_options
      )

  # Process parameter overrides if this is a parameterized report and we have
  # a recent enough version of knitr.
  processParameters <- FALSE
  if (config$HasParameters == "true") {
    if (compareVersion("1.10.18", versions$knitr) > 0) {
      cat("Override parameter processing skipped with knitr version < 1.10.18.\n")
    } else if (compareVersion("0.7.3", versions$rmarkdown) > 0) {
      cat("Override parameter processing skipped with rmarkdown version < 0.7.3.\n")
    } else {
      cat("Processing parameters.\n")
      processParameters <- TRUE
    }
  }

  if (processParameters) {
    overridesRDS <- file.path(config$OutputDir, ".overrides.rds")
    parameters <- connect$paramsWithOverrides(config$RmdFile, overridesRDS)

    parametersRDS <- file.path(config$OutputDir, ".parameters.rds")
    parametersJSON <- file.path(config$OutputDir, ".parameters.json")
    
    saveRDS(parameters, parametersRDS)
    # FIXME: jsonlite detection. assuming it's available because of Shiny dependency.
    write(jsonlite::toJSON(parameters, auto_unbox = TRUE), file = parametersJSON)

    render_args$params <- parameters
  }

  output_file <- do.call(rmarkdown::render, render_args)

  # rmarkdown::render bases its output file name on the input file name, but
  # in the process it can change it arbitrarily (to remove spaces and special
  # characters, which choke pandoc or something). As a simple mechanism for
  # communicating the resulting file path back to the server, just write it
  # directly to disk using a hidden file (".index"). The eos argument is
  # necessary to prevent a null terminator from being added.
  writeChar(basename(output_file), file.path(config$OutputDir, ".index"), eos = NULL)
})
