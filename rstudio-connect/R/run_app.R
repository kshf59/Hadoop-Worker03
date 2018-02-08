#
# run_app.R
#
# Copyright (C) 2017 by RStudio, Inc.
#
local({
  # Prefer to use Sys.getenv("USER") here, but at the time of this writing
  # rsandbox doesn't set $USER, so it's always root
  if (identical(.Platform$OS.type, "unix") && identical(system("whoami", intern = TRUE), "root")) {
    stop("Attempted to run application as ", Sys.getenv("USER"))
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
      "Version",
      "InstalledRVersion",
      "BundleRVersion",
      "AppDir",
      "BookmarkDir",
      "Port",
      "SharedSecret",
      "WorkerId",
      "AppMode",
      "HTMLInclude",
      "IgnorePackrat",
      "ErrorSanitization",
      "TraceFlushReact",
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

  PRODUCT_NAME <- "RStudio Connect"

  MIN_R_VERSION <- "2.15.1"
  MIN_SHINY_VERSION <- "0.7.0"
  MIN_RMARKDOWN_VERSION <- "0.1.90"
  MIN_KNITR_VERSION <- "1.5.32"

  # We can have a more stringent requirement for the Shiny version when using
  # rmarkdown
  MIN_SHINY_RMARKDOWN_VERSION <- "0.9.1.9005"

  source(file = file.path(config$ConnectDir, "R", "connect.R"), local = TRUE)

  connect$enforceMinimumRVersion(MIN_R_VERSION)
  if (config$IgnorePackrat != "true") {
    connect$enforceInstalledRVersion(config$InstalledRVersion)
    connect$enforceAssumedRVersion(config$BundleRVersion)
    connect$enforcePackratHealth()

    connect$configureAppLibDir(config$AppDir)
  }

  packages <- c("shiny", "rmarkdown", "knitr", "jsonlite", "RJSONIO", "htmltools")
  versions <- connect$getVersions(packages)

  cat(paste("Server version: ",config$Version, "\n", sep=""))
  connect$printEnvironment()
  connect$printVersions(packages, versions)
  
  connect$enforcePackageVersion("shiny", MIN_SHINY_VERSION, versions$shiny)

  # Trying to use rmd, verify package.
  if (identical(config$AppMode, "shinyrmd")){
    connect$enforcePackageVersion("rmarkdown", MIN_RMARKDOWN_VERSION, versions$rmarkdown)
    connect$enforceDependentPackageVersion("shiny", MIN_SHINY_RMARKDOWN_VERSION, versions$shiny, "rmarkdown")
    connect$enforceDependentPackageVersion("knitr", MIN_KNITR_VERSION, versions$knitr, "rmarkdown")
  }

  connect$addPandocToPath()
  connect$configureBrowseURL()
  connect$fixupCrossPackageReferences()

  library(shiny)

  Sys.setenv(
    SHINY_PORT = config$Port,
    SHINY_SERVER_VERSION = config$Version
  )

  options(shiny.sanitize.errors = (config$ErrorSanitization=="true"))
  options(shiny.sharedSecret = config$SharedSecret)

  if (exists("setServerInfo", envir=asNamespace("shiny"))) {
    shiny:::setServerInfo(shinyServer = TRUE,
                          version = config$Version,
                          edition = "Connect")
  }
  
  helpers <- connect$configureShinyHelpers(versions)
  shinyFilter <- connect$configureShinyFilter(config, helpers, versions)
  options(shiny.http.response.filter=shinyFilter)

  connect$configureShinyBookmarking(config$BookmarkDir)

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

  if (config$TraceFlushReact == "true") {
    # This is a special connection that Shiny detects when it wants to send
    # updates back to Shiny Server/RStudio Connect.
    assign(".shiny__stdout", stdout(), envir=globalenv())
  }

  connect$retry(function() {
    if (identical(config$AppMode, "shiny")){
      # Support for Shiny 0.7+
      # If we need the "host" argument, it is Shiny 0.9+.
      runApp(config$AppDir,
             port=port,
             launch.browser=FALSE,
             workerId=config$WorkerId)
    } else if (identical(config$AppMode, "shinyrmd")){
      library(rmarkdown)
      # Passing envir=new.env() to rmarkdown::run gives us a little isolation
      # from the variables defined in this file.
      # See: https://github.com/rstudio/rmarkdown/issues/1124
      # See: https://github.com/rstudio/connect/issues/8321
      rmarkdown::run(file=NULL, dir=config$AppDir,
                     shiny_args=list(
                         port=port,
                         launch.browser=FALSE,
                         workerId=config$WorkerId),
                     render_args = if (compareVersion("1.7", versions$rmarkdown) <= 0) list(envir = globalenv()),
                     auto_reload=FALSE)
    } else {
      stop(paste("Unclear Shiny mode:", config$AppMode))
    }
  }, isRetryable = function(e) {
    # Exact error match with httpuv::startServer
    e$message == "Failed to create server"
  }, delay = function(iter) { (iter-1) * 0.5 })
  
  invisible(environment())
})
