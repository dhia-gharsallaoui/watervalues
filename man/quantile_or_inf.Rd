% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/math_functions.R
\name{quantile_or_inf}
\alias{quantile_or_inf}
\title{Calculate the quantile if there is no infinite or missing value.
Return \code{-Inf} in the other case.}
\usage{
quantile_or_inf(x, q_ratio, inaccessible_states = 0)
}
\arguments{
\item{x}{numeric vector whose quantile is wanted.}

\item{q_ratio}{Numeric in [0,1]. Probability of the quantile.}

\item{inaccessible_states}{Numeric in [0,1]. Tolerance of inaccessible states.
For example if equal to 0.9 we delete the state if this states is inaccessible by 90\% of scenarios.}
}
\description{
Calculate the quantile if there is no infinite or missing value.
Return \code{-Inf} in the other case.
}
