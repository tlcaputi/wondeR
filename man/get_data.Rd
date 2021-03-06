% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/line-graphs.R
\name{get_data}
\alias{get_data}
\title{get_data: Pull data from CDC Wonder using wonderpy and put it into a good format}
\usage{
get_data(
  ROOTPATH = "",
  MCD1 = c(),
  MCD2 = c(NA),
  RUNNAME = "",
  replace = T,
  by_vars = c("sex", "race", "hispanic"),
  pypath = "/path/to/python.exe"
)
}
\arguments{
\item{ROOTPATH}{path to directory that includes an "input" and "output" folder}

\item{MCD1}{ICD10 codes}

\item{MCD2}{ICD10 codes that must ALSO be included in the MCD}

\item{RUNNAME}{Name for the data you will pull}

\item{replace}{Default True, if False or if the data file does not exist it will pull data}

\item{by_vars}{Segment the data by sex, race, hispanic, and/or state. Year is always included.}

\item{pypath}{Defaults to where python in CMD. You can also set the path to your Python 3 EXE file}
}
\description{
get_data: Pull data from CDC Wonder using wonderpy and put it into a good format
}
\examples{
df <- get_data(
  ROOTPATH = "C:/Users/tcapu/Desktop/wonderdd",
  MCD1 = c("X40","X41","X42","X43","X44","X60","X61","X62","X63","X64","Y10","Y11","Y12","Y13","Y14"),
  MCD2 = c("T40.2","T40.3","T40.4"),
  RUNNAME = "year_state_sex_race_opioids",
  replace = T,
  by_vars = c("race", "hispanic"),
  pypath = T
)
}
\keyword{pull}
