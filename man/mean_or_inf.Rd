% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/math_functions.R
\name{mean_or_inf}
\alias{mean_or_inf}
\title{Calculate the mean if there is no infinite or missing value.
Return \code{-Inf} in the other case.}
\usage{
mean_or_inf(x, inaccessible_states)
}
\arguments{
\item{x}{numeric vector whose mean is wanted.}

\item{inaccessible_states}{Numeric in [0,1]. Tolerance of inaccessible states.
For example if equal to 0.9 we delete the state if this states is inaccessible by 90\% of scenarios.}
}
\description{
Calculate the mean if there is no infinite or missing value.
Return \code{-Inf} in the other case.
}
