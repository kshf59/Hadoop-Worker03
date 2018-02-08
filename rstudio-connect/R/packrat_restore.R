#
# packrat_restore.R
#
# Copyright (C) 2017 by RStudio, Inc.
#

# !diagnostics suppress=connect

# Let Packrat know that RStudio Connect is about to deploy.
Sys.setenv(RSTUDIO_CONNECT = 1)

# Helper function for displaying a section header.
section <- function(title) {

  # construct header (initial part of section)
  header <- paste("# ", title, sep = "")

  # determine tail size
  n <- min(getOption("width", 78), 80) - nchar(header)
  tail <- ""
  if (n > 2) {
    tail <- paste(" ", paste(rep("-", n - 1), collapse = ""), sep = "")
  }

  msg <- paste(header, tail, "\n", sep = "")
  cat(msg)
}

# Prefer to use Sys.getenv("USER") here, but at the time of this writing
# rsandbox doesn't set $USER, so it's always root
if (identical(.Platform$OS.type, "unix") &&
    identical(system("whoami", intern = TRUE), "root"))
{
  stop("Attempted to run application as ", Sys.getenv("USER"), ".")
}

# Ensure a directory exists + is writable. The directory will be created
# if it does not already exist. The normalized path is returned on success.
ensure_dir_writeable <- function(path) {

  # Attempt to create directory if necessary.
  if (!file.exists(path)) {
    if (!dir.create(path, recursive = TRUE)) {
      fmt <- "Failed to create directory: %s\n"
      stop(sprintf(fmt, path))
    }
  }

  # Ensure we can write a temporary file to this directory.
  normalized <- normalizePath(path, mustWork = TRUE)
  tmp <- tempfile(tmpdir = normalized)
  if (!file.create(tmp)) {
    fmt <- paste(
      "Failed to write temporary file to directory: %s",
      "Read / write permissions to this folder are required",
      "for successful deployment.",
      sep = "\n"
    )
    stop(sprintf(fmt, path))
  }
  unlink(tmp)

  # Return normalized path.
  normalized
}

# Read config directives from stdin and put them in the environment.
fd <- file("stdin")
d <- read.dcf(fd)

config <- as.list(structure(
  as.vector(d),
  names = colnames(d)
))

# Verify the config structure arriving over STDIN.
expectedFields <- c(
    "ConnectDir",
    "InstalledRVersion",
    "RLibraryDir",
    "PackratCacheDir",
    "SourcePackageDir",
    "DownloadDir",
    "HttpProxy",
    "HttpsProxy",
    "ExternalPackages",
    "CompilationConcurrency"
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
MIN_PACKRAT_VERSION <- "0.4.5.17"

# configurable compilation parallelization.
Sys.setenv(MAKEFLAGS = paste0("-j", config$CompilationConcurrency))

# set proxy settings, if present
if (config$HttpProxy != '') {
  Sys.setenv(http_proxy = config$HttpProxy)
}
if (config$HttpsProxy != '') {
  Sys.setenv(https_proxy = config$HttpsProxy)
}

# Set R options. We use 'curl' primarily because it's the best-supported
# downloader with packrat; we also force curl to follow redirects (just in
# case Packrat doesn't do it on its own).
options(
  download.file.method = "curl",
  download.file.extra  = "-L -f"
)

# this creates an object called 'connect' which provides various routines
source(file = file.path(config$ConnectDir, "R", "connect.R"), local = TRUE)

connect$enforceMinimumRVersion(MIN_R_VERSION)
connect$enforceInstalledRVersion(config$InstalledRVersion)

# Ensure that the R library directory exists and is writable.
section("Validating R library read / write permissions")
rLibraryDir <- path.expand(file.path(config$RLibraryDir, getRversion()))
rLibraryDir <- ensure_dir_writeable(rLibraryDir)

# use this library path
.libPaths(rLibraryDir)

packages <- c("packrat")
versions <- connect$getVersions(packages, lib.loc = rLibraryDir)

vendoredPackagesDir <- file.path(config$ConnectDir, "ext", "R")
vendoredPackages <- list.files(vendoredPackagesDir,
                               pattern = "packrat.*\\.tar\\.gz",
                               full.names = TRUE)
details <- file.info(vendoredPackages)

## Find the most recent vendored packrat package.
mostRecent <- details[which.max(as.POSIXct(details$mtime)), ]
packratArchive <- rownames(mostRecent)
if (length(packratArchive) == 0) {
  fmt <- "Could not find a packrat package in %s.\n"
  stop(sprintf(fmt, vendoredPackagesDir))
} else if (length(packratArchive) > 1) {
  fmt <- "Expected to only find one packrat package in %s, but found %s.\n"
  stop(sprintf(fmt, vendoredPackagesDir, paste(packratArchive, collapse = ",")))
}

packratArchiveSHA <- connect$shaFromFilename(packratArchive)
packratInstalledSHA <- connect$safeDescriptionField("packrat", "GithubSHA1", lib.loc = rLibraryDir)
section("Validating packrat installation")
cat("Installed packrat SHA is: ", packratInstalledSHA, "\n", sep = "")
cat("Packaged packrat SHA is:  ", packratArchiveSHA,   "\n", sep = "")

if (is.null(packratInstalledSHA) || packratArchiveSHA != packratInstalledSHA) {

  if (!is.null(packratInstalledSHA)) {
    fmt <- "Packrat version %s is out-of-date; a new version will be installed.\n"
    cat(sprintf(fmt, versions$packrat), sep = "")
    remove.packages("packrat", lib = rLibraryDir)
  }

  cat("Installing packrat from ", packratArchive, ".\n", sep = "")

  # attempt to install packrat
  install.packages(packratArchive, repos = NULL, lib = rLibraryDir)

  # Refresh the packrat version after the upgrade so we can dump its value.
  versions$packrat <- connect$safePackageVersion("packrat", lib.loc = rLibraryDir)
} else {
  cat("Packrat is up-to-date.", sep = "\n")
}

connect$printVersions(packages, versions)

# Force umask to 0027, which allows group reading of files and directories and
# prevents access by others. This means that the packrat cache will be
# available to all members of our group.
#
# This is after we install our private version of packrat but before we
# attempt to install any app-specific packages.
Sys.umask(mode = "0027")

# Ensure that the packrat cache directory exists and is writable.
section("Validating packrat cache read / write permissions")
packratCacheDir <- path.expand(file.path(config$PackratCacheDir, getRversion()))
packratCacheDir <- ensure_dir_writeable(packratCacheDir)

connect$fixupPackageHashes("packrat")

# When configured, set the environment variable telling Packrat the location
# of the package source directory that is scanned for package sources before
# attempting to obtain the package from a remote location.
if (config$SourcePackageDir != "") {
  fmt <- "Using packrat package source directory: %s\n"
  cat(sprintf(fmt, config$SourcePackageDir), sep = "")
  Sys.setenv(R_PACKRAT_SRC_OVERLAY = config$SourcePackageDir)
}

# Use a distinct location for packrat-downloaded packages (avoid the
# packrat/src that might have come from the bundle).
Sys.setenv(
    R_PACKRAT_SRC_DIR = config$DownloadDir
)
# Do not scan the src dir for packages (anything present there would be seen
# as untrusted).
options(packrat.untrusted.packages = character())

options(packrat.verbose.cache = TRUE,
        packrat.connect.timeout = 10)

packages <- strsplit(config$ExternalPackages, ",")[[1]]

opts <- list(
    auto.snapshot = FALSE,
    use.cache = TRUE,
    project = getwd(),
    persist = FALSE
)
if(length(packages) > 0) {
    opts$external.packages <- packages
}

do.call(packrat::set_opts, opts)

# Try and stay around 70 characters wide for this output. We will inject
# timestamping which consumes about 30 characters. That's pretty wide.
RESTORE_ERROR <- "
Unable to fully restore the R packages associated with this deployment.
Please review the preceding messages to determine which package
encountered installation difficulty and the cause of the failure.

Some typical reasons for package installation failures:
  * A system library needed by the R package is not installed.
    Some of the most common package dependencies are cataloged at:
    https://github.com/rstudio/shinyapps-package-dependencies

  * The R package requires a newer version of R.

  * The C/C++ compiler is outdated. This is often true for packages
    needing C++11 features.

  * The R package is Windows-only or otherwise unavailable for this
    operating system.

  * The package is housed in a private repository that requires
    authentication to access. For more details on this, see:
    http://docs.rstudio.com/connect/admin/process-management.html#private-packages

The package description and documentation will list system requirements
and restrictions.

Please contact your RStudio Connect administrator for further help
resolving this issue.
"

Sys.setenv(R_PACKRAT_CACHE_DIR = packratCacheDir)

tryCatch({
  section("Installing required R packages with `packrat::restore()`")
  packrat::restore(overwrite.dirty = TRUE,
                   prompt = FALSE,
                   restart = FALSE)
}, error = function(e) {
  cat(paste(e))

  cat(RESTORE_ERROR)
  quit(save = "no", status = 1)
})
