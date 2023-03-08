## Purpose
Containing Python and R scripts for web scraping information from Clinicaltrials.gov to check if outcomes databases need update.

## Getting Started
### Prerequisites
For **NCT_check.ipynb**:
1. Python 3
2. Jupyter notebook

For **NCT_check.R**:
1. R version 4.0.4
2. R studio 2022.07.1

File needed:
1. Source database.csv (Before using the script, please use augment.source 02162023_v5.R to augment source database)

Script needed:
1. NCTs_chek.R

Directories:<br>
Save the file in ***csv*** folder of the database you are currently working on, and the script in ***r*** folder.<br>

### Usage
Make sure the augmented source database (Source database.csv) is in *UTF-8* encoding in order to avoid special characters usually in authors' names.
After importing the file, you are good to start the process of web scraping. And the output file will once again save as *UTF-8* encoded files.
