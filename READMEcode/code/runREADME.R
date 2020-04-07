library(PythonInR)
library(wondeR)

df <- get_data(
  ROOTPATH = "C:/Users/tcapu/Google Drive/modules/wondeR/READMEcode", # this should include an "input" and "output" subdirectory
  RUNNAME = "sex_race_overdose", # Name of the run
  replace = T, # Default True, if False then this will not collect data
  pypath = "C:/Users/tcapu/AppData/Local/Programs/Python/Python38/python.exe", # Path to your python3.exe file (see above)

  ## Collect data on deaths that include these ICD10 codes
  MCD1 = c("T36-T50"), ## Any of these codes...
  MCD2 = c("X40-X44", "X60-X64", "X85", "Y10-Y14"), ## AND any of these codes. Defaults to c(NA), which is All death codes

  ## Segment the data based upon these variables
  by_vars = c("state", "sex", "race") # can be sex, age, race, hispanic, state
)






out <- plot_grid(
  df, # Data frame from get_data

  ## Should be same as above
  ROOTPATH = "C:/Users/tcapu/Google Drive/modules/wondeR/READMEcode",
  RUNNAME = "sex_race_overdose",

  ## Convenience arguments
  minwonderyear = 1999, # Min year that WONDER collects
  maxwonderyear = 2018, # Max year that WONDER collects

  ## Multiple Lines within the Same Plot
  # Create the names for the groups that you want
  groups = c(
    "No Expansion Before 2019",
    "Expanded in 2014",
    "Expanded Between 2015 and 2018"
  ),

  # Write the conditions for those groups as strings
  group_conditions = c(
    "is.na(aca_date) | year(aca_date) > 2018",
    "year(aca_date) == 2014",
    "T"
  ),

  # Legend Title for the Groups
  group_title = "Medicaid",

  # Will add n= values to the group labels
  include_n = T,

  # If True, will only include data from state-years with data for all groups
  listwise = F,


  ## Multiple plots in a grid
  # Segment data by x and y
  grid_vars = c("sex", "race"),

  ## Plot Arguments
  xlab = "Year",
  ylab = "Crude Rate\n(Per 100k Deaths)",
  colpalette = "Dark2", # ggplot theme
  vline = T, # If logical, no vertical line. If numeric/date, a dotted vertical line

  ## Plot Saving arguments
  save = T, # If True, a plot will be saved
  out_fn = T, # If logical, will be named after RUNNAME
  width = 6, # width in inches
  height = 4, # height in inches

  ## Do you want to return the data or just the plot?
  include_data = T
)

ggsave("./output/Fig1.png", out[[1]], width = 10, height = 7)
