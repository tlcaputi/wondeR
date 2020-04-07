pacman::p_load(lubridate, dplyr)


ROOTPATH <- "C:/Users/tcapu/Google Drive/PublicHealthStudies/wonderdd"
setwd(ROOTPATH)

wonder <- data.frame(expand.grid(c(state.name, "District of Columbia"), 1980:2020))
names(wonder) <- c("state", "year")

## Marijuana Data
marijuana <- read.csv("./input/marijuana_laws.csv", header = T, stringsAsFactors = F)
names(marijuana) <- gsub('ï..', '', names(marijuana))
tmp <- merge(wonder, marijuana, by="state", all.x = T)
for(v in names(marijuana)[2:6]){
  vname <- paste0("i_", v)
  tmp[, vname] <- ifelse(is.na(tmp[, v]) | tmp$year < tmp[, v], 0, 1)
}


## ACA Medicaid Expansion
acaexp <- read.csv("./input/aca-expansions-state.csv", header = T, stringsAsFactors = F)
tmp2 <- merge(tmp,
  acaexp %>% rename(
    state = state_name,
    acaexp_date = date,
    acaexp_event = event
  ), by="state", all.x = T)

tmp2 <- tmp2 %>% mutate(
  acaexp_date = as.Date(acaexp_date, format = "%m/%d/%Y"),
  imedexp = case_when(
    is.na(acaexp_date) ~ 0,
    year(acaexp_date) <  year ~ 1,
    year(acaexp_date) >  year ~ 0,
    year(acaexp_date) == year ~ as.numeric(acaexp_date - ymd(sprintf("%s-01-01", year))) / 365
  )
)



## State data
state_data <- read.csv("./input/state_data.csv", header = T, stringsAsFactors = F)
names(state_data) <- gsub('ï..', '', names(state_data))
names(state_data) <- gsub("YEAR", "year", names(state_data))
names(state_data) <- gsub("STATEFIP", "state", names(state_data))

## Merge everything together
tmp3 <- merge(tmp2, state_data, by=c("state", "year"), all = T)
names(tmp3) <- tolower(names(tmp3))



marlaws <- read.csv("./input/marlaws.csv", header = T, stringsAsFactors = F)
names(marlaws) <- gsub('ï..', "", names(marlaws))
tmp3$stateabb <- state.abb[match(tmp3$state, state.name)]
tmp3$stateabb <- ifelse(tmp3$state == "District of Columbia", "DC", tmp3$stateabb)
tmp4 <- merge(tmp3, marlaws, by=c("stateabb"), all = T)

shover <- read.csv("./input/shover_data.csv", header = T, stringsAsFactors = F)
names(shover) <- tolower(names(shover))
names(shover) <- ifelse(names(shover) %in% c("state", "year"), names(shover), paste0("shover_", names(shover)))
tmp5 <- merge(tmp4, shover, by=c("state", "year"), all = T)



state_vars_clean <- tmp5 %>% rename(
  ## identifier variables
  state = state,
  abb = state_abbrv,
  year = year,
  ## marijuana policies
  mml = i_mml_effective_date,
  rml = i_marijuana_rec,
  mml_date = mml_effective_date,
  rml_date = marijuana_rec,
  ## medicaid expansion
  aca = imedexp,
  aca_date = acaexp_date,
  ## demographics
  female = sex_female,
  male = sex_male,
  white = race_white,
  nonwhite = race_other,
  adultciv = popstat_adult_civilian,
  child = popstat_child,
  adultarm = popstat_armed_forces,
  vet = vetstat_yes,
  employed = empstat_employed,
  nilf = empstat_nilf,
  unemployed = empstat_unemployed,
  emparm = empstat_armed_forces,
  avgage = age,
  totfaminc = ftotval,
  totindinc = inctot,
  ) %>% select(
  state,
  abb,
  year,
  mml,
  rml,
  aca,
  mml_date,
  rml_date,
  mml_ed,
  rml_sales_ed,
  aca_date,
  female,
  male,
  white,
  nonwhite,
  adultciv,
  child,
  adultarm,
  vet,
  employed,
  nilf,
  unemployed,
  emparm,
  avgage,
  totfaminc,
  totindinc,
  starts_with("shover"),
)

state_vars_clean$aca_date <- ymd(state_vars_clean$aca_date)
statevars <- state_vars_clean
write.csv(statevars, "./input/state_vars_clean.csv", row.names = F)
save(statevars, file = "C:/Users/tcapu/Google Drive/modules/wondeR/data/statevars.rda")
