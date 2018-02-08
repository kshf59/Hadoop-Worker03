#
# build_site.R
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
      "BundleRVersion"
  )

  missingFields <- setdiff(expectedFields, names(config))
  unexpectedFields <- setdiff(names(config), expectedFields)
  if (length(missingFields)!=0 || length(unexpectedFields)!=0) {
    fmt <- "Unexpected configuration; missing fields: %s; unexpected fields: %s"
    stop(sprintf(fmt,
                 paste0(missingFields, collapse=", "),
                 paste0(unexpectedFields, collapse=", ")))
  }


  # TODO: update min-versions
  MIN_R_VERSION <- "2.15.1"
  MIN_RMARKDOWN_VERSION <- "0.9.5.5"
  MIN_KNITR_VERSION <- "1.11"

  source(file = file.path(config$ConnectDir, "R", "connect.R"), local = TRUE)

  connect$enforceMinimumRVersion(MIN_R_VERSION)
  connect$enforceInstalledRVersion(config$InstalledRVersion)
  connect$enforceAssumedRVersion(config$BundleRVersion)
  connect$enforcePackratHealth()

  connect$configureAppLibDir(getwd())

  packages <- c("rmarkdown", "knitr")
  versions <- connect$getVersions(packages)

  connect$printEnvironment()
  connect$printVersions(packages, versions)
  
  connect$enforcePackageVersion("rmarkdown", MIN_RMARKDOWN_VERSION, versions$rmarkdown)
  connect$enforceDependentPackageVersion("knitr", MIN_KNITR_VERSION, versions$knitr, "rmarkdown")

  connect$addPandocToPath()
  connect$configureBrowseURL()
  connect$fixupCrossPackageReferences()

  # Sites are not allowed to be parameterized at this point.
  # Sites are not generated as self-contained.

  # rmarkdown::render_site does not support output retargeting. Therefore,
  # we must render in-place. The server has already taken care of cloning
  # the source into our output directory and set that as our working directory.
  output_file <- rmarkdown::render_site(envir = new.env())
  # rmarkdown::render_site returns a path to the output relative to the
  # output directory.
    
  output_dir <- dirname(output_file)
  output_file <- basename(output_file)

  if (output_dir != dirname(output_dir)) {
    cat(paste("Promoting site content from", output_dir, "to", getwd(), "\n"))

    # Determine the top-level of the output directory.
    root_output_dir <- output_dir
    while(TRUE) {
      d <- dirname(root_output_dir)
      if (d == dirname(d)) {
        # We have reached either "/" or "." and cannot go higher.
        break
      } else {
        root_output_dir <- d
      }
    }

    here_files <- list.files(".")
    output_files <- list.files(output_dir)
    # 1. remove everything except the output directory.
    # 2. promote everything in the output directory here.
    # 3. remove the output directory.
    lapply(here_files, function(filename) {
      if (filename != root_output_dir) {
        unlink(filename, recursive = TRUE)
      }
    })

    lapply(output_files, function(filename) {
      oldname <- file.path(output_dir, filename)
      newname <- filename
      file.rename(oldname,newname)
    })

    unlink(root_output_dir, recursive = TRUE)
  }
  
  # Write the name of the output file to disk in the ".index" file as a simple
  # mechanism for communicating the resulting file path back to the server.
  # The eos argument is necessary to prevent a null terminator from being
  # added.
  writeChar(output_file, ".index", eos = NULL)
})
