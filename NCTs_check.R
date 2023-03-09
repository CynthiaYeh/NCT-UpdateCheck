# DESCRIPTION -------------------------------------------------------------
# Purpose        : Clinicaltrials.gov Update Check
# Script Version : 2 March 2023
# Database       :
# Created by     : Cynthia Yeh
#-------------------------------------------------------------------------
# Last run by  : (name) - Certara Confidential
# Date run     : 2 March 2023
# -------------------------------------------------------------------------
# Software : Version 2022.07.1 - 2009-2022 RStudio, PBC
#            R version 4.0.4
# Platform : Lenovo ThinkPad T490
# Environment : Windows 10 Enterprise, Intel(R) Core(TM) i7-10510U CPU @ 1.80 GHz 64-bit OS

# DATASET NAMING -------------------------------------------------------------
# refs              <- augmented source DB (imported from Source database.csv)
# refs_nct          <- filtered references for clintrials.gov, will be used for web scraping 
# refs_merge        <- merged set of refs_nct and refs
# last_update_date  <- list that contains last outcome measures update date
# last_post_date    <- list that contains last update posted date


rm(list = ls())

##### Dependencies #####
# Please first install the packages if they are not in the library
# install.packages("rvest")
# install.packages("tidyverse")
# install.packages("dplyr")
# install.packages("httr")
# install.packages("lubridate")
library(rvest)
library(tidyverse)
library(dplyr)
library(httr)
library(lubridate)


##### Directories #####
dirHome <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(dirHome)

dirSource <- '../csv'
dirResults <- '../csv'

refs <- read.csv(file = paste(dirSource, "Source database.csv", sep = "/"), header = TRUE, encoding = "UTF-8")
names(refs)[1] <- "search"
# Filter the clintrials references that are included in the outcomes DB
refs_nct <- refs %>% filter(database == "yes" &
                              search == "clinicaltrials.gov")


##### Web Scraping from ClinTrials.gov #####
# Record last change date for outcome measures on ClinTrials.gov
last_update <- c()

for (i in refs_nct$url){
  url <- gsub("show", "history", i)
  # print(i)
  
  # Let it sleep between every session to avoid connection issue
  # Sys.sleep(3)
  message("Getting page: ", url)
  
  page <- read_html(GET(url, timeout(2000)))
  df <- page %>% html_table(fill = TRUE)
  df_oc <- df[[1]]
  
  df_oc <- filter(df_oc, rowSums(is.na(df_oc)) != ncol(df_oc))
  df_last_oc <- df_oc[grep("Outcome Measures", df_oc$Changes), ]
  df_last_oc <- tail(df_last_oc, 1)
  if (nrow(df_last_oc) == 0){
    message("The clinical trial has not updated outcome measures before")
    last_update <- append(last_update, NA)
    }
  else {
    print(df_last_oc$`Submitted Date`)
    last_update <- append(last_update, df_last_oc$`Submitted Date`)
    }
  }

# Reocrd last update posted date for studies on ClinTrials.gov
last_post <- c()

for (i in refs_nct$url){
  # temp_refs <- refs_nct$url[2]
  url <- gsub("show", "archive", i)
  # print(i)
  
  # Let it sleep between every session to avoid connection issue
  # Sys.sleep(3)
  message("Getting page: ", url)
  
  page <- read_html(GET(url, timeout(2000)))
  df <- page %>% html_table(fill = TRUE)
  df <- df[[1]]
  
  ind <- which(grepl("Last Update Posted", df$X1))
  
  print(df$X2[ind])
  last_post <- append(last_post, df$X2[ind])
}


##### Date Cleaning #####
# Convert labeled date to mm-dd-yyyy
last_update_date <- mdy(last_update)
last_post_date <- mdy(last_post)

# Add columns for update dates
refs_nct$last_outcome_change <- last_update_date
refs_nct$nct_update_needed <- refs_nct$search.date < refs_nct$last_outcome_change
refs_nct$last_update_posted <- last_post_date


##### Join refs_nct and refs #####
# Merge update date columns back to source DB
refs_merge <- refs %>%
  left_join(refs_nct %>% select(source.number, last_outcome_change, nct_update_needed, last_update_posted), by = "source.number")

# Convert date columns to desired format
dates <- c("search.date", "last_outcome_change", "last_update_posted")

for (k in dates) {
  refs_merge[,k] <- paste('="', as.character(refs_merge[,k]), '"', sep = '') 
}

refs_merge <- refs_merge %>%
  mutate_at(dates, ~str_replace(., "=\"NA\"", ""))


##### Write to CSV files #####
write.csv(refs_merge, paste(dirResults,'NCTs checking.csv',sep = '/'), na = "", row.names = FALSE, fileEncoding = "UTF-8")
