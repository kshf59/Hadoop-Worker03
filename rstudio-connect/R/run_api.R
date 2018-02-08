#
# run_api.R
#
# Copyright (C) 2016 by RStudio, Inc.

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
        "Port",
        "SharedSecret",
        "WorkerId",
        "IgnorePackrat"
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
    MIN_PLUMBER_VERSION <- "0.4.2"
    
    HOST <- "127.0.0.1"

    source(file = file.path(config$ConnectDir, "R", "connect.R"), local = TRUE)

    connect$enforceMinimumRVersion(MIN_R_VERSION)
    if (config$IgnorePackrat != "true") {
      connect$enforceInstalledRVersion(config$InstalledRVersion)
      connect$enforceAssumedRVersion(config$BundleRVersion)
      connect$enforcePackratHealth()

      connect$configureAppLibDir(config$AppDir)
    }

    packages <- c("plumber", "jsonlite", "httpuv")
    versions <- connect$getVersions(packages)

    cat(paste("Server version: ",config$Version, "\n", sep=""))
    connect$printEnvironment()
    connect$printVersions(packages, versions)

    connect$enforcePackageVersion("plumber", MIN_PLUMBER_VERSION, versions$plumber)

    connect$addPandocToPath()
    connect$configureBrowseURL()
    connect$fixupCrossPackageReferences()

    library(plumber)

    options(plumber.sharedSecret = config$SharedSecret)

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

    plumb <- getOption("run_api.plumber", default = plumber::plumb)
    PlumberEndpoint <- getOption("run_api.PlumberEndpoint", default = plumber::PlumberEndpoint)

    connect$retry(
      function() {
        plum <<- plumb(dir = config$AppDir)
        rootHandled <- connect$plumberDoesHandleRoot(plum)
        if (!rootHandled) {
            connect$configurePlumberRootHelper(plum, PlumberEndpoint)
        }
        plum$run(host = HOST, port = port, swagger = !rootHandled)
        # TODO: Worker ID filter
      },
      isRetryable = function(e) {
        # Exact error match with httpuv::startServer
        e$message == "Failed to create server"
      },
      delay = function(iter) {
        (iter - 1) * 0.5
      }
    )
    
    invisible(environment())
})

