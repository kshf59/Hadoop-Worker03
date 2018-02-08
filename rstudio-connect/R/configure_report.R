#
# configure_report.R
#
# Copyright (C) 2017 by RStudio, Inc.
#
local({
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
      "Version",
      "InstalledRVersion",
      "BundleRVersion",
      "AppDir",
      "RmdFile",
      "Port",
      "SharedSecret",
      "OutputDir",
      "WorkerId",
      "Reconnect",
      "ReconnectMs",
      "DisabledProtocols",
      "TransportDebugging"
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
  MIN_RMARKDOWN_VERSION <- "0.7.3"
  MIN_SHINY_RMARKDOWN_VERSION <- "0.9.1.9005"
  MIN_KNITR_VERSION <- "1.10.18"

  source(file = file.path(config$ConnectDir, "R", "connect.R"), local = TRUE)

  connect$enforceMinimumRVersion(MIN_R_VERSION)
  connect$enforceInstalledRVersion(config$InstalledRVersion)
  connect$enforceAssumedRVersion(config$BundleRVersion)
  connect$enforcePackratHealth()

  connect$configureAppLibDir(dirname(config$RmdFile))
  
  packages <- c("shiny", "rmarkdown", "knitr", "RJSONIO", "jsonlite", "htmltools")
  versions <- connect$getVersions(packages)

  cat(paste("Server version: ",config$Version, "\n", sep=""))
  connect$printEnvironment()
  connect$printVersions(packages, versions)

  connect$enforcePackageVersion("rmarkdown", MIN_RMARKDOWN_VERSION, versions$rmarkdown)
  connect$enforceDependentPackageVersion("shiny", MIN_SHINY_RMARKDOWN_VERSION, versions$shiny, "rmarkdown")
  connect$enforceDependentPackageVersion("knitr", MIN_KNITR_VERSION, versions$knitr, "parameterized reports")

  connect$addPandocToPath()
  connect$fixupCrossPackageReferences()

  # We prefer jsonlite to RJSONIO but support both. RJSONIO::toJSON does not
  # support auto_unbox but unboxes by default (you need to explicitly wrap
  # single-element lists/vectors)
  if (is.na(versions$jsonlite)) {
    if (is.na(versions$RJSONIO)) {
        stop("Unable to find either jsonlite or RJSONIO.")
    } else {
      saveJSON <- function(overrides, filename) {
        write(RJSONIO::toJSON(overrides = TRUE), file = filename)
      }
    }
  } else {
    saveJSON <- function(overrides, filename) {
      write(jsonlite::toJSON(overrides, auto_unbox = TRUE), file = filename)
    }
  }
  
  library(shiny)
  library(rmarkdown)

  Sys.setenv(
    SHINY_PORT = config$Port,
    SHINY_SERVER_VERSION = config$Version
  )

  options(shiny.sanitize.errors = TRUE)
  options(shiny.sharedSecret = config$SharedSecret)

  if (exists("setServerInfo", envir=asNamespace("shiny"))) {
    shiny:::setServerInfo(shinyServer = TRUE,
                          version = config$Version,
                          edition = "Connect")
  }
  
  helpers <- connect$configureShinyHelpers(versions)
  filter <- connect$configureShinyFilter(config, helpers, versions, isVariantParamForm = TRUE)
  options(shiny.http.response.filter=filter)

  # Port can be either a TCP port number, in which case we need to cast to
  # integer; or else a Unix domain socket path, in which case we need to
  # leave it as a string
  port <- suppressWarnings(as.integer(config$Port))
  if (is.na(port)) {
    port <- config$Port
    attr(port, 'mask') <- strtoi('0077', 8)
  }
  # This must be the last message echo'd on stdout of our "special" messages.
  # (Not currently true with RSC)
  cat(paste("\nStarting R with process ID: '",Sys.getpid(),"'\n", sep=""))

  cat("port",port,class(port),"\n")

  shiny_args <- list(
      launch.browser=FALSE,
      port = port,
      workerId = config$WorkerId
      )

  overridesRDS  <- file.path(config$OutputDir, ".overrides.rds")
  overridesJSON <- file.path(config$OutputDir, ".overrides.json")

  overrides <- list()

  if (file.exists(overridesRDS)) {
    overrides <- readRDS(overridesRDS)
  }

  connect$retry(function() {
    overrides <<- knit_params_ask(file = config$RmdFile,
                                  params = overrides,
                                  shiny_args = shiny_args)
  }, isRetryable = function(e) {
    # Exact error match with httpuv::startServer
    e$message == "Failed to create server"
  }, delay = function(iter) { (iter-1) * 0.5 })

  if (is.null(overrides)) {
    # Configuration was canceled. leave any existing overrides files alone.

    # We do not use a non-zero exit code because there may be prior
    # customization that should still be used. Let the caller detect the
    # presence of customization separately from how this program exits.
  } else {
   
    # Write RDS/JSON if there are customized values or remove previous customizations if not.
    #
    # This means that a report without customization does not have overrides
    # files. If we revisit this decision, we will want to work-around an
    # annoyance: jsonlite::toJSON writes [] instead of {} when we have an
    # empty list (empty lists have no names!).
    #
    # RJSONIO has an emptyNamedList variable jsonlite::toJSON(RJSONIO::emptyNamedList)
    #
    # Here is how you initialize an empty named list:
    # > l <- list()
    # > names(l) <- character()
    # > l
    # named list()
    # > jsonlite::toJSON(l)
    # {} 

    if (length(overrides)) {
      saveRDS(overrides, overridesRDS)
      saveJSON(overrides, overridesJSON)
    } else {
      if (file.exists(overridesRDS)) {
        file.remove(overridesRDS)
      }
      if (file.exists(overridesJSON)) {
        file.remove(overridesJSON)
      }
    }
  }

  invisible(environment())
})
