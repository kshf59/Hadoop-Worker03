#!/bin/bash

# Copyright (C) 2016 by RStudio, Inc.

# WARNING: THIS SCRIPT EXECUTES AS ROOT! STEP CAREFULLY!

# The purpose of this script is to enable a launched task to outlive
# the server process that launched it, preserving enough information
# (stdout/stderr, pid, exit code) for a future process to recover
# that information.
#
# See the connect/job package for the relevant Go code.

# Precondition: OUTDIR exists and can be modified by the current user

# In an environment where LANG is unset, try our best to discover one.
# https://github.com/rstudio/rmarkdown/blob/fe27d632842db0b8bcaadddd0aebc5ccadd8c9b2/R/pandoc.R#L539-L564
# https://github.com/rstudio/rmarkdown/issues/31
if [ -e /etc/default/locale ]; then
    . /etc/default/locale
fi
if [ $LANG ] && [ "$LANG" != "C" ]; then
    # $LANG exists and is set. Just use it
    :
else
    # $LANG is not set or is "C", which is insufficient; we need to infer it.
    if (locale -a | grep -q -e '^C.UTF-8$'); then
        # We have C.UTF-8, use it.
        LANG="C.UTF-8"
    else
        LANG="en_US.UTF-8"
    fi
fi
export LANG

exec "$@"
