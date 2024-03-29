% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Plot_functions.R
\name{just_plot_report}
\alias{just_plot_report}
\title{Plot simulation variables comparison and real Ov. cost (for watervalues)}
\usage{
just_plot_report(data, plot_var, plot_type = T)
}
\arguments{
\item{data}{A data.table contains the simulation results and  real Ov. cost.
Obtained using the function plot_results()}

\item{plot_var}{list of variables to plot.}

\item{plot_type}{boolean. True to plot by area. False to plot by simulation}
}
\value{
a \code{ggplot} object
}
\description{
Plot simulation variables comparison and real Ov. cost (for watervalues)
}
