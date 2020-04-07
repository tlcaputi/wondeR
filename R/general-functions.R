#' plot_grid: Flexible function to plot data from get_data
#'
#' @param codes Data frame from get_data
#' @keywords plot
#' @export
#' @examples
#' expand_codes("V80-V89", "V90.0-V90.8", "V87")'

expand_codes <- function(codes){

  out <- c()
  for(code in codes){
    if(grepl("-", code)){
      coderange <- strsplit(code, "-") %>% unlist()
      numberrange <- gsub("[A-Za-z]", "", coderange)
      letterrange <- gsub("[0-9]|[.]", "", coderange)
      assert(letterrange[1] == letterrange[2])
      if(grepl("[.]", numberrange[1])){
        num_digits1 <- nchar(strsplit(numberrange[1], "[.]")[[1]][2])
        num_digits2 <- nchar(strsplit(numberrange[2], "[.]")[[1]][2])
        num_digits <- min(c(num_digits1, num_digits2), na.rm = T)
      } else{
        num_digits <- 0
      }
      nums <- seq(as.numeric(numberrange[1]), as.numeric(numberrange[2]), by=1/(10^num_digits))
      expanded <- paste0(letterrange[1], format(nums, nsmall=num_digits))
      out <- c(out, expanded)
    } else{
      out <- c(out, code)
    }
  }

  return(out)
}
