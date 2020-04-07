#' get_data: Pull data from CDC Wonder using wonderpy and put it into a good format
#'
#' @param ROOTPATH path to directory that includes an "input" and "output" folder
#' @param MCD1 ICD10 codes
#' @param MCD2 ICD10 codes that must ALSO be included in the MCD
#' @param RUNNAME Name for the data you will pull
#' @param replace Default True, if False or if the data file does not exist it will pull data
#' @param by_vars Segment the data by sex, race, hispanic, and/or state. Year is always included.
#' @param pypath Defaults to where python in CMD. You can also set the path to your Python 3 EXE file
#' @keywords
#' @export
#' @examples
#' df <- get_data(
#'   ROOTPATH = "C:/Users/tcapu/Desktop/wonderdd",
#'   MCD1 = c("X40","X41","X42","X43","X44","X60","X61","X62","X63","X64","Y10","Y11","Y12","Y13","Y14"),
#'   MCD2 = c("T40.2","T40.3","T40.4"),
#'   RUNNAME = "year_state_sex_race_opioids",
#'   replace = T,
#'   by_vars = c("race", "hispanic"),
#'   pypath = T
#' )


get_data <- function(
  ROOTPATH = "",
  MCD1 = c(),
  MCD2 = c(NA),
  RUNNAME = "",
  replace = T,
  by_vars = c("sex", "race", "hispanic"),
  pypath = T
){

  # if(pypath){
  #   py <- system("where python", intern = T)
  #   pypath <- gsub("\\\\", "/", py)
  # }

  pyConnect(pypath)
  setwd(ROOTPATH)
  assert(dir.exists(ROOTPATH))
  inp_fn <- sprintf("%s/input/%s_pull.csv", ROOTPATH, RUNNAME)

  if(!file.exists(inp_fn) | replace){

    # by_vars <- unique(c("year", "state", by_vars))
    by_vars <- unique(c("year", by_vars))

    pySet("by_vars", by_vars)
    pySet("MCD1", MCD1)
    pySet("MCD2", MCD2)

  pyExec(
"
if MCD1 is None:
  MCD1 = [None]
else:
  MCD1 = MCD1.x

if MCD2 is None:
  MCD2 = None
else:
  MCD2 = MCD2.x
"
  )


  pyExec(sprintf(
'
from wonderpy.pulldata import wonder
ROOTPATH = "{}".format("%s")
wonder(
    MCD_ICD_10_CODE_1 = MCD1,
    MCD_ICD_10_CODE_2 = MCD2,
    RUN_NAME="{}".format("%s"),
    by_variables = by_vars.x,
    existing_file = False,
    download_dir = "{}\\\\input".format(ROOTPATH),
    just_go=False
)
', gsub("[/]","\\\\\\\\", ROOTPATH), RUNNAME))

  }


  wonder <- read.csv(inp_fn, header = T, stringsAsFactors = F)
  names(wonder) <- gsub("Ten.Year.Age.Groups.Code", "agegcode", names(wonder))
  names(wonder) <- gsub("Ten.Year.Age.Groups", "ageg", names(wonder))
  names(wonder) <- gsub("Notes", "notes", names(wonder))
  names(wonder) <- gsub("Gender.Code", "sexcode", names(wonder))
  names(wonder) <- gsub("Gender", "sex", names(wonder))
  names(wonder) <- gsub("Hispanic.Origin.Code", "hispaniccode", names(wonder))
  names(wonder) <- gsub("Hispanic.Origin", "hispanic", names(wonder))
  names(wonder) <- gsub("Race.Code", "racecode", names(wonder))
  names(wonder) <- gsub("Race", "race", names(wonder))
  names(wonder) <- gsub("State.Code", "fips", names(wonder))
  names(wonder) <- gsub("State", "state", names(wonder))
  names(wonder) <- gsub("Year.Code", "yearcode", names(wonder))
  names(wonder) <- gsub("Year", "year", names(wonder))
  names(wonder) <- gsub("Deaths", "deaths", names(wonder))
  names(wonder) <- gsub("Population", "pop", names(wonder))
  names(wonder) <- gsub("Crude.Rate.Lower.95..Confidence.Interval", "crlo95", names(wonder))
  names(wonder) <- gsub("Crude.Rate.Upper.95..Confidence.Interval", "crhi95", names(wonder))
  names(wonder) <- gsub("Crude.Rate.Standard.Error", "crse", names(wonder))
  names(wonder) <- gsub("Crude.Rate", "cr", names(wonder))
  names(wonder) <- gsub("Age.Adjusted.Rate.Lower.95..Confidence.Interval", "aarlo95", names(wonder))
  names(wonder) <- gsub("Age.Adjusted.Rate.Upper.95..Confidence.Interval", "aarhi95", names(wonder))
  names(wonder) <- gsub("Age.Adjusted.Rate.Standard.Error", "aarse", names(wonder))
  names(wonder) <- gsub("Age.Adjusted.Rate", "aar", names(wonder))

  wonder <- wonder %>% mutate_at(
      vars(deaths, pop, contains("fips"), starts_with("cr"), starts_with("aar")),
      funs(as.numeric(trimws(.)))
    )

  if("race" %in% names(wonder)){
    wonder$race <- ifelse(grepl("American Indian", wonder$race), "Amer. Indian or AL Native", wonder$race)
  }

  if("race" %in% names(wonder) & "hispanic" %in% names(wonder)){

    other_by_vars <- by_vars[!by_vars %in% c("race", "hispanic")]
    wonder <- wonder %>% mutate(
        race_rc = case_when(
          !grepl("Not", hispanic) ~ "Hispanic",
          grepl("Black", race) &  grepl("Not", hispanic) ~ "Black Not Hispanic",
          grepl("White", race) &  grepl("Not", hispanic) ~ "White Not Hispanic",
          !grepl("Black|White", race) &  grepl("Not", hispanic) ~ "Other Not Hispanic",
        )
      ) %>%
      filter(!is.na(race_rc)) %>%
      group_by_at(vars(one_of(c("year", "names", "race_rc", other_by_vars)))) %>%
      mutate(
        cr = sum(deaths, na.rm = T) / sum(pop, na.rm = T),
        pop = sum(pop, na.rm = T),
        deaths = sum(deaths, na.rm = T),
      ) %>% ungroup()

  }

  if("state" %in% names(wonder)){
    wonder <- wonder %>% filter(state!="" & !is.na(state))
    state_vars <- load(statevars)
    # state_vars <- read.csv("./input/state_vars_clean.csv", header = T, stringsAsFactors = F)
    state_vars <- state_vars %>% mutate_at(vars(aca_date), ymd)
    df <- merge(wonder, state_vars, by=c("state", "year"), all.x = T)

    
  } else{
    df <- wonder
  }

  return(df)
}



#' plot_grid: Flexible function to plot data from get_data
#'
#' @param df Data frame from get_data
#' @param minwonderyear minimum year from Wonder, default 1999
#' @param maxwonderyear maximum year from wonder, default 2018
#' @param groups These are for multiple lines in the same plot. Name the groups here....
#' @param group_conditions ... and set their conditions as a string here.
#' @param grid_vars These are for multiple plots in a grid
#' @param group_title Name of groups, default "",
#' @param listwise Default False, if True then delete all groups that don't have the max number of observations
#' @param ROOTPATH ROOTPATH that includes input and output folders
#' @param RUNNAME Name for the data
#' @param vline If numeric, locaiton of a vertical line
#' @param include_n Defualt False, if True then group labels are given Ns
#' @param save Default True, if False does not save the plot
#' @param out_fn Default RUNNAME.png
#' @param width Width of the plot in inches
#' @param height Height of the plot in inches
#' @param xlab X axis label, Default Year
#' @param ylab Y axis label, default Crude Rate Per 100,000
#' @param colpalette ggplot2 colortheme
#' @keywords
#' @export
#' @examples
#' plot_grid(
#'   df,
#'   minwonderyear = 1999,
#'   maxwonderyear = 2018,
#'   groups = NULL,
#'   group_conditions = NULL,
#'   grid_vars = c("race"),
#'   ROOTPATH = "C:/Users/tcapu/Desktop/wonderdd",
#'   RUNNAME = "year_state_sex_race_opioids",
#'   listwise = F,
#'   vline = F,
#'   save = T,
#'   width = 6,
#'   height = 4,
#'   group_title="",
#'   colpalette="Dark2"
#' )



plot_grid <- function(
  df,
  minwonderyear = 1999,
  maxwonderyear = 2018,
  groups = c(
    sprintf("No Expansion Before %s", maxwonderyear),
    "Expanded in 2014",
    sprintf("Expanded Between 2015 and %s", maxwonderyear)
  ),
  group_conditions = c(
    "is.na(aca_date) | year(aca_date) > maxwonderyear",
    "year(aca_date) == 2014",
    "T"
  ),
  grid_vars = c("sex", "race"),
  ROOTPATH = "",
  RUNNAME = "year_state_sex_race_firearms",
  save = T,
  out_fn = T,
  listwise = T,
  vline = T,
  include_n = F,
  width = 6,
  height = 4,
  xlab = "Year",
  ylab = "Crude Rate\n(Per 100k Deaths)",
  group_title = "",
  colpalette = "Dark2"
  ){


  if("race_rc" %in% names(df) & "race" %in% grid_vars) grid_vars <- gsub("race", "race_rc", grid_vars)
  assert(all(grid_vars %in% names(df)))


  if(out_fn) out_fn <- sprintf("%s/output/%s.png", ROOTPATH, RUNNAME)


  df <- df %>% filter(!is.na(year), !grepl("Total", notes))

  if(listwise){
    df <- df %>% group_by(state, year) %>%
            mutate(num_obs = n()) %>% ungroup() %>%
            filter(num_obs==max(.$num_obs, na.rm = T))
  }


  if(length(groups) != 0){

    tmp <- df %>% mutate(grp = eval(parse(text=txt)))

    if("state" %in% names(df)){

      txt <- "case_when("
      for(i in 1:length(groups)){
        tmp <- sprintf("%s ~ '%s',", group_conditions[i], groups[i])
        txt <- paste0(txt, tmp)
      }
      txt <- paste0(txt, ")")

      tmp <- tmp %>%
                group_by(grp) %>%
                mutate(
                  num_in_grp = n_distinct(state)
                ) %>%
                ungroup()

      if(include_n){
        tmp <- tmp %>%
              mutate(grp = sprintf("%s (n=%s)", grp, num_in_grp))
      }

    }

  gbyvars <- c("year", "grp", grid_vars)

  tmp <- tmp  %>%
          filter(!is.na(deaths) & !is.na(pop)) %>%
          group_by_at(vars(all_of(gbyvars))) %>%
          summarise(
            num_obs = n(),
            cr = sum(deaths)/sum(pop)
          ) %>% ungroup() %>%
          filter(
            !grepl("^NA", grp),
            !is.na(grp),
            grp!="NA"
          )

  } else{

    gbyvars <- c("year", grid_vars)

    tmp <- df %>%
            filter(!is.na(deaths) & !is.na(pop)) %>%
            group_by_at(vars(all_of(gbyvars))) %>%
            summarise(
              num_obs = n(),
              cr = sum(deaths)/sum(pop)
            ) %>% ungroup()
  }


  p <- ggplot(tmp)
  if(length(groups) == 0) grp <- NULL
  p <- p + geom_line(aes(x = year, y=cr*100000, colour=grp))
  if(is.numeric(vline) | is.Date(vline)) p <- p + geom_vline(xintercept=vline, lty="dashed")
  p <- p + theme_bw() + theme(legend.position=c(0.25,0.9), legend.background = element_rect(linetype = 1, size = 0.5, colour = 1))
  p <- p + labs(
    y = ylab,
    x = xlab
  )

  if(length(grid_vars) == 1){
    p <- p + facet_wrap(vars(get(grid_vars[1])), ncol =1)
  } else{
    if(length(grid_vars) == 2){
      p <- p + facet_grid(vars(get(grid_vars[1])), vars(get(grid_vars[2])))
    }
  }

  p <- p + scale_x_continuous(minor_breaks = seq(1999, 2018, by=1))
  p <- p + guides(color=guide_legend(title=group_title))
  p <- p + theme(legend.position="bottom")

  if(is.character(colpalette)) p <- p + scale_color_brewer(palette=colpalette)

  if(save){
    assert(dir.exists(ROOTPATH))
    ggsave(out_fn, p, width = width, height = height)
  }

  return(p)
}
