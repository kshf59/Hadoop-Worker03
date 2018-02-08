#
# connect.R
#
# Copyright (C) 2017 by RStudio, Inc.
#

## a dir.exists for R < 3.2.0
dir_exists <- function(x) {
  file_test('-d', x)
}

connect_buildHelpers <- function() {

  PRODUCT_NAME <- "RStudio Connect"

  enforceMinimumRVersion <- function(minRVersion) {
    systemRVersion <- as.character(getRversion())
    if (compareVersion(minRVersion, systemRVersion) > 0) {
      # R is out of date
      stop(paste("R version ", systemRVersion, " found. ",
                 PRODUCT_NAME, " requires at least ",
                 MIN_R_VERSION, ".", sep = ""))
    }
  }

  enforceInstalledRVersion <- function(expectedRVersion, quitter=quit) {
    systemRVersion <- as.character(getRversion())
    if (!identical(systemRVersion, expectedRVersion)) {
      cat(paste("The R installation at ", R.home(),
                " was expected to have version ", expectedRVersion,
                " but is reporting version ", systemRVersion,
                "; the R installation may have changed. ",
                "RStudio Connect needs to be restarted. ",
                "Please contact the server administrator.\n", sep = ""))
      quitter(save = "no", status = 14)
    }
  }

  # connect$enforceAssumedRVersion expects it is enforcing version for a
  # post-build step.
  enforceAssumedRVersion <- function(expectedRVersion, quitter=quit) {
    systemRVersion <- as.character(getRversion())
    if (!identical(expectedRVersion, systemRVersion)) {
      if (identical(expectedRVersion,"")) {
        ## We have no prior R version; the app was never built.
        cat("Library was not successfully built; exiting to trigger rebuild.\n")
        quitter(save = "no", status = 13)
      } else {
        ## The system R version has changed since the packrat library was built.
        cat(paste("Library was built against R version ", expectedRVersion,
                  " while the curent system R version is ", systemRVersion,
                  "; exiting to trigger rebuild.\n", sep = ""))
        quitter(save = "no", status = 13)
      }
    }
  }

  # Check that packrat has all resources installed
  enforcePackratHealth <- function(quitter=quit) {
    lib_path <- file.path("packrat/lib", R.version$platform, getRversion())
    packages <- list.files(lib_path, full.names = TRUE)
    links <- Sys.readlink(packages)
    missing <- nzchar(links) & !dir_exists(links)
    if (any(missing)) {
      writeLines(c(
         "The following packages are not installed:",
         paste("-", shQuote(basename(packages)[missing]), collapse = ", "),
         "RStudio Connect will attempt to reinstall these packages."
       ))

       quitter("no", status = 13)
    }
  }

  enforcePackage <- function(name, curVersion) {
    if (is.na(curVersion)) {
      stop(paste("The ", name, " package was not found in the library.", sep = ""))
    }
  }

  enforcePackageVersion <- function(name, minVersion, curVersion) {
    enforcePackage(name, curVersion)
    if (compareVersion(minVersion, curVersion) > 0) {
      stop(paste("Found ", name, " with version ", curVersion, ". ",
                 PRODUCT_NAME, " requires at least ", minVersion, ".",
                 sep = ""))
    }
  }

  enforceDependentPackage <- function(name, curVersion, other) {
    if (is.na(curVersion)) {
      stop(paste("The ", name, " package was not found in the library ",
                 "but is needed for ", other, ".", sep = ""))
    }
  }

  enforceDependentPackageVersion <- function(name, minVersion, curVersion, other) {
    enforceDependentPackage(name, curVersion, other)
    if (compareVersion(minVersion, curVersion) > 0) {
      stop(paste("Found ", name, " with version ", curVersion, ". ",
                 PRODUCT_NAME, " requires at least ", minVersion,
                 " to use with ", other, ".", sep = ""))
    }
  }

  safePackageVersion <- function(name, lib.loc = NULL) {
    if (system.file(package = name, lib.loc = lib.loc) == "") {
      # Package isn't installed
      NA
    } else {
      as.character(packageVersion(name, lib.loc = lib.loc))
    }
  }

  safeDescriptionField <- function(package, field, lib.loc = NULL) {
    if (system.file(package = package, lib.loc = lib.loc) == "") {
      # package isn't installed
      NULL
    } else {
      desc <- packageDescription(package, lib.loc = lib.loc)
      desc[[field]]
    }
  }

  shaFromFilename <- function(filename) {
    ## takes /path/to/package_hex.tar.gz or /path/to/package_hex.tgz
    ## and gives hex
    no_ext <- tools::file_path_sans_ext(tools::file_path_sans_ext(basename(filename)))
    tail(strsplit(no_ext, "_")[[1]], n = 1)
  }

  addPandocToPath <- function() {
    pandoc <- Sys.getenv("RSTUDIO_PANDOC")
    if (pandoc != '') {
      Sys.setenv(PATH = paste(Sys.getenv("PATH"), pandoc, sep = .Platform$path.sep))
    }
  }

  # params_with_overrides combines the parameters in an Rmd (known to have
  # parameters) with an optional overrides file.
  paramsWithOverrides <- function(rmd, overridesRDS) {
    # FIXME: use the correct encoding when reading the Rmd
    knit_params <- knitr::knit_params(readLines(rmd))

    ## Merge the default values with the user-specified values.
    parameters <- list()
    for (param in knit_params) {
      parameters[[param$name]] <- param$value
    }

    if (file.exists(overridesRDS)) {
      knit_params_names = names(knit_params)
      overrides <- readRDS(overridesRDS)
      for (name in names(overrides)) {
        # Copy in only parameters that continue to be in the document. If
        # rendering is presented values for parameters it does not support, we
        # may err. https://github.com/rstudio/connect/issues/5282
        if (name %in% knit_params_names) {
          parameters[[name]] <- overrides[[name]]
        } else {
          cat("Discarding obsolete parameter: ", name, "\n", sep = "")
        }
      }
    }
    parameters
  }

  getVersions <- function(packages, lib.loc = NULL) {
    versions <- structure(lapply(packages, function(p) {
      safePackageVersion(p, lib.loc = lib.loc)
    }), names = packages)
    versions$R <- as.character(getRversion());
    versions
  }

  printVersions <- function(packages, versions) {
    lapply(c("R", packages), function(n) {
      cat(paste(n," version: ", versions[[n]], "\n", sep = ""))
    })
    invisible()
  }

  printEnvironment <- function() {
    cat(paste("LANG: ", Sys.getenv("LANG"), "\n", sep = ""))
    invisible()
  }

  # This code is to recalculate the hashes in packrat.lock according to the
  # version of packrat installed on this system. If the hash algorithm differs
  # between the client and the server, this fixup is necessary in order for
  # the cache to ever hit.
  fixupPackageHashes <- function(packratDir) {
    lockFile <- file.path(packratDir, "packrat.lock")
    descDir <- file.path(packratDir, "desc")

    if (!file.exists(lockFile)) {
      # No lock file!? This... is not going to go well.
      cat("Cannot fixup package hashes: the packrat.lock file is missing.\n")
      return(invisible())
    }
    if (!dir_exists(descDir)) {
      # Extra DESCRIPTION files not available, abort
      cat("Cannot fixup package hashes: the desc dir is missing.\n")
      return(invisible())
    }

    # Check if we can use the installed packrat; it must have a two-arg version
    # of hash()
    if (is.null(asNamespace("packrat")$hash) ||
        length(formals(asNamespace("packrat")$hash)) < 2) {
      # Nope
      cat("Cannot fixup package hashes: packrat:::hash is missing or has the wrong signature.\n")
      return(invisible())
    }

    lockInfo <- read.dcf(lockFile, all = TRUE)

    packages <- list.files(descDir, full.names = TRUE)
    names(packages) <- basename(packages)

    if (!setequal(names(packages), na.omit(lockInfo[,"Package"]))) {
      # Packages are not the same as desc files. For correctness and security
      # reasons we should stop early.
      cat("Cannot fixup package hashes: the set of package descriptions is not correct.\n")
      return(invisible())
    }

    # Helper function that returns a path to our bundled DESCRIPTION file.
    descriptionLookupFn <- function(depPkg) {
      if (depPkg %in% names(packages)) {
        packages[[depPkg]]
      } else {
        ""
      }
    }
    # Attempt to calculate hashes. Reasons this might fail include:
    # - Installed packrat version is too old, doesn't have two-argument :::hash
    #   function
    # - Installed packrat version is too new, no longer has :::hash function (not
    #   the case as of this writing, but, who knows what can happen in the future)
    # - Malformed or missing DESCRIPTION file
    hashes <- try({
      sapply(packages, function(pkg) {
        packrat:::hash(pkg, descriptionLookupFn)
      })
    })
    if (inherits(hashes, "try-error")) {
      # Hash calculations did not succeed.
      cat("Cannot fixup package hashes: there was an exception.\n")
      return(invisible())
    }

    # Overwrite the hash values with our new ones
    lockInfo[,"Hash"] <- hashes[lockInfo[,"Package"]]

    # Make backup of the old lockfile (for diagnostic purposes)
    file.copy(lockFile, paste0(lockFile, ".bak"))
    # Write lockfile
    write.dcf(lockInfo, lockFile)

    cat("Audited package hashes with local packrat installation.\n")
    return(invisible())
  }

  fixupCrossPackageReferences <- function(lib.loc = NULL) {
    if (!is.na(safePackageVersion("knitr", lib.loc))) {
      if (!is.na(safePackageVersion("evaluate", lib.loc))) {
        # Make sure knitr is using the version of evaluate::evaluate available
        # for this content.
        #
        # https://github.com/rstudio/connect/issues/7861
        # https://github.com/rstudio/packrat/issues/407
        # https://github.com/yihui/knitr/issues/1441
        knitr::knit_hooks$set(evaluate = evaluate::evaluate)
      }
    }
  }

  # appdir is the directory where the packrat files may be found
  configureAppLibDir <- function(appDir) {
    # Supplement the libDirs with our Packrat library.
    libdir <- normalizePath(file.path(appDir, "packrat", "lib", R.version$platform, getRversion()), mustWork = FALSE)
    if (file.exists(libdir)) {
      # Add libdir to path
      .libPaths(c(libdir, .libPaths()))
      cat(file = stderr(), "Using Packrat dir ", libdir, "\n", sep = "")
    } else {
      cat(file = stderr(), "Warning: Packrat dir ", libdir," does not exist\n", sep = "")
    }
  }

  # package_has_function is a wrapper around "exists" which returns TRUE if
  # the named package contains the provided function.
  #
  # We stub this function in test.
  package_has_function <- function(pname, fname) {
    exists(fname, where = asNamespace(pname), mode = "function", inherits = FALSE)
  }

  # Checks whether a plumber router has `GET /` defined
  # This function should only ever be called in a block guaranteed to have
  # Plumber version 0.4.0 or greater.
  plumberDoesHandleRoot <- function(router){
    doesHandleRoot <- function(router) {
      if ("plumberstatic" %in% class(router)) {
        # It's a static file server. We'll assume that it handles root.
        return(TRUE)
      }

      handleRoot <- lapply(router$endpoints, function(ends){
        lapply(ends, function(e){
          "GET" %in% e$verbs && e$path == "/"
        })
      })
      any(unlist(handleRoot))
    }
    ret <- doesHandleRoot(router)
    if(!ret && !is.null(router$mounts) && !is.null(router$mounts$`/`)) {
      doesHandleRoot(router$mounts$`/`)
    } else {
      ret
    }
  }

  configurePlumberRootHelper <- function(router, PlumberEndpoint) {
    ep <- PlumberEndpoint$new("GET", "/", function(res) {
      res$setHeader("Location", "__swagger__/")
      res$status <- 307L
    }, envir = router$environment)
    ep$comments <- "
                RStudio Connect added this endpoint to redirect to the API docs by default.
                Once you define a base handler (i.e.: `GET /`), RStudio Connect will stop adding
                this redirector.
                "
    router$handle(endpoint = ep)
  }

  configureShinyBookmarking <- function(bookmarkDir) {
    # We cannot configure the location for bookmarkable state if
    # shiny::shinyOptions does not exist.
    if (package_has_function("shiny", "shinyOptions")) {
      if (nchar(bookmarkDir) > 0) {
        cat("Using Shiny bookmarking base directory ", bookmarkDir, "\n", sep = "")
        save.interface <- function(id, callback) {
          username <- Sys.info()[["effective_user"]]
          dirname <- file.path(bookmarkDir, username, id)
          if (dir_exists(dirname)) {
            stop("Directory ", dirname, " already exists")
          } else {
            dir.create(dirname, recursive = TRUE, mode = "0700")
            callback(dirname)
          }
        }
        load.interface <- function(id, callback) {
          username <- Sys.info()[["effective_user"]]
          dirname <- file.path(bookmarkDir, username, id)
          if (!dir_exists(dirname)) {
            stop("Session ", id, " not found")
          } else {
            callback(dirname)
          }
        }
        shiny::shinyOptions(
          save.interface = save.interface,
          load.interface = load.interface
        )
      } else {
        save.interface <- function(id, callback) {
          stop("This server is not configured for saving sessions to disk.")
        }
        load.interface <- function(id, callback) {
          stop("This server is not configured for saving sessions to disk.")
        }
        shiny::shinyOptions(
          save.interface = save.interface,
          load.interface = load.interface
        )
      }
    }
  }

  configureShinyHelpers <- function(versions) {
    requestUser <- function(req) { NULL }
    if (is.na(versions$jsonlite)) {
      if (is.na(versions$RJSONIO)) {
        stop("Unable to find either jsonlite or RJSONIO.")
      } else {
        requestUser <- function(req) {
          if (!is.null(req$HTTP_SHINY_SERVER_CREDENTIALS)) {
            RJSONIO::fromJSON(req$HTTP_SHINY_SERVER_CREDENTIALS)[["user"]]
          }
        }
        cat("Using RJSONIO for JSON processing\n")
      }
    } else {
      requestUser <- function(req) {
        if (!is.null(req$HTTP_SHINY_SERVER_CREDENTIALS)) {
          jsonlite::fromJSON(req$HTTP_SHINY_SERVER_CREDENTIALS)[["user"]]
        }
      }
      cat("Using jsonlite for JSON processing\n")
    }

    htmlEscape <- function(s) { NULL }
    if (is.na(versions$htmltools)) {
      htmlEscape <- shiny:::htmlEscape
    } else {
      htmlEscape <- htmltools::htmlEscape
    }
    return(list(requestUser = requestUser,
                htmlEscape = htmlEscape))
  }

  configureShinyFilter <- function(config, helpers, versions, isVariantParamForm = FALSE) {
    renderTemplate <- function(template, req) {
      user <- NULL
      tryCatch({
        user <- helpers$requestUser(req)
      }, error = function(e) {
        stop(e)
      })

      val <- gsub("\\{\\{#user}}(.*?)\\{\\{/user}}",
                  ifelse(is.null(user), "", "\\1"),
                  template)

      val <- gsub("\\{\\{user}}",
                  ifelse(is.null(user), "", helpers$htmlEscape(user)),
                  val)
      return(val)
    }

    html_include_file <- NULL
    if (!is.null(config$HTMLInclude)) {
      if (file.exists(config$HTMLInclude)) {
        html_include_file <- normalizePath(config$HTMLInclude)
      }
    }

    baseHref <- function() {
      HTML(sprintf("<base href=\"_w_%s/\">
    <script type=\"text/javascript\">
(function() {
  var workerId = '_w_%s';
  // remove base href if worker ID is in url
  if (window.location.href.indexOf(workerId) > 0) {
    document.querySelector('base').removeAttribute('href');
  }
})();
</script>", config$WorkerId, config$WorkerId))
    }

    injectedVersions <- function() {
      HTML(sprintf("
      <script type=\"text/javascript\">
      var __connect = {
        shiny: '%s'
      }
      </script>
      ", versions$shiny))
    }

    injectTop <- function() {
      paste(
        HTML("<head>"),
        baseHref(),
        injectedVersions(),
        sep = "\n"
      )
    }

    # Load the SockJS client and Shiny server client, and then initialize the config for the
    # Shiny server client. Get `shiny-server-client.js` by cloning
    # https://github.com/rstudio/shiny-server-client and building it with `make`.
    injectList <- list(
      tags$script(src = '__assets__/sockjs-0.3.min.js'),
      tags$script(src = '__assets__/shiny-server-client.js'),
      tags$script(
        sprintf(
          "preShinyInit({reconnect:%s,reconnectTimeout:%s,disableProtocols:%s,transportDebugging:%s,token:true,workerId:true,subappTag:true,extendSession:true,fixupInternalLinks:true});",
          config$Reconnect, config$ReconnectMs, config$DisabledProtocols, config$TransportDebugging
        )
      ),
      tags$link(rel = 'stylesheet',
                type = 'text/css',
                href = '__assets__/rstudio-connect.css')
    )
    if (isVariantParamForm) {
      injectList <- append(injectList, list(
        tags$link(rel = 'stylesheet',
                  type = 'text/css',
                  href = '__assets__/rstudio-params.css'),
        tags$script(src = '__assets__/rstudio-params.js'),
        # we remove bootstrap below so we need to insert the standalone version of the CSS since it
        # depends on bootstrap
        tags$link(
          rel = 'stylesheet',
          type = 'text/css',
          href = '__assets__/bootstrap-datepicker.standalone.min.css'
        )
      ))
    }
    injectList <- append(injectList, c(HTML("</head>"), sep = "\n"))
    inject <- do.call(paste, injectList)

    injectBottomTemplate <- if (!is.null(html_include_file)) {
      paste(c("\\1", readLines(html_include_file, warn = FALSE)), collapse = "\n")
    }

    filter <- function(req, response) {
      if (response$status < 200 || response$status > 300) return(response)

      # Don't break responses that use httpuv's file-based bodies.
      if ('file' %in% names(response$content)) {
        return(response)
      }

      if (!grepl("^text/html\\b", response$content_type, perl = TRUE)) {
        return(response)
      }

      # HTML files served from static handler are raw. Convert to char so we
      # can inject our head content.
      if (is.raw(response$content)) {
        response$content <- rawToChar(response$content)
      }

      response$content <- sub("<head>", injectTop(), response$content,
                              ignore.case = TRUE)

      response$content <- sub("</head>", inject, response$content,
                              ignore.case = TRUE)

      if (isVariantParamForm) {
        # remove bootstrap
        #
        # Note that this is very brittle and totally dependant on the way shiny injects bootstrap. For
        # example, if rmarkdown where to inject LINKs as <link href=foo"></link> (with a closing tag),
        # the regular expression would break the HTML.
        response$content <- sub(
          "<link[ \t]+href=.shared/bootstrap.*?>", "", response$content,
          ignore.case = TRUE)
        response$content <- gsub(
          "<script[ \t]+src=.shared/bootstrap.*?/script>", "", response$content,
          ignore.case = TRUE)
      }

      if (!is.null(html_include_file) &&
          !grepl("__subapp__", req$QUERY_STRING, fixed = TRUE)) {
        response$content <- sub("(<body(\\s[^>]*)?>)",
                                renderTemplate(injectBottomTemplate, req),
                                response$content, perl = TRUE, ignore.case = TRUE)
      }

      return(response)
    }
    filter
  }

  # Configures the "browser" option so Connect does not attempt to spawn a
  # browser.
  configureBrowseURL <- function() {
    options(browser = function(url) {
      cat("Cannot visit", url, "because the browseURL function is disabled.\n")
    })
  }

  #' Retries a function a number of times.
  #' @param fn The function that is executed. This is NOT simply an expression.
  #' @param isRetryable A function that determines if an error is permanent or retryable.
  #' @param n The maximum number of retry attempts.
  #' @param delay A function that returns a number specifying the number of (fractional) seconds between attempts.
  retry <- function(fn, isRetryable = function(x) FALSE, n = 5, delay = function(iter) 0) {
    err <- NULL
    for (i in seq(n)) {
      tryCatch({
        return(fn())
      }, error = function(e) {
        err <- e
        if (i < n && isRetryable(err)) {
          sleepytime <- delay(i)
          cat(paste0("Retrying after ", sleepytime, "s delay due to error: ", err$message, "\n", sep = ""))
          Sys.sleep(sleepytime)
        } else {
          stop(err$message)
        }
      })
    }
    stop(err$message)
  }

  return(list(
    enforceMinimumRVersion = enforceMinimumRVersion,
    enforceAssumedRVersion = enforceAssumedRVersion,
    enforcePackratHealth = enforcePackratHealth,
    enforceInstalledRVersion = enforceInstalledRVersion,
    enforcePackage = enforcePackage,
    enforcePackageVersion = enforcePackageVersion,
    enforceDependentPackage = enforceDependentPackage,
    enforceDependentPackageVersion = enforceDependentPackageVersion,
    safePackageVersion = safePackageVersion,
    safeDescriptionField = safeDescriptionField,
    shaFromFilename = shaFromFilename,
    addPandocToPath = addPandocToPath,
    paramsWithOverrides = paramsWithOverrides,
    configureAppLibDir = configureAppLibDir,
    plumberDoesHandleRoot = plumberDoesHandleRoot,
    configurePlumberRootHelper = configurePlumberRootHelper,
    configureShinyBookmarking = configureShinyBookmarking,
    configureShinyHelpers = configureShinyHelpers,
    configureShinyFilter = configureShinyFilter,
    configureBrowseURL = configureBrowseURL,
    getVersions = getVersions,
    printVersions = printVersions,
    printEnvironment = printEnvironment,
    fixupPackageHashes = fixupPackageHashes,
    fixupCrossPackageReferences = fixupCrossPackageReferences,
    retry = retry
  ))
}
connect <- connect_buildHelpers()
