/*****************************************************************************
* Description: see README
*****************************************************************************/

/*****************************************************************************
* 0a. Project Configuration
*
* Adjust as needed
*****************************************************************************/
// Root directory of the project
global DIR_PROJ "/Users/federle/Documents/GitHub/military-rate-revised"

// Font face used in figures
graph set window fontface "Palatino"


/*****************************************************************************
* 0b. Miscellaneous variable definitions and procedures
*
* Do not adjust
*****************************************************************************/
cd $DIR_PROJ

global DIR_DATA_RAW "${DIR_PROJ}/data/01_raw"
global DIR_DATA_PROCESSED "${DIR_PROJ}/data/02_processed"
global DIR_DATA_EXPORTS "${DIR_PROJ}/data/03_exports"
global DIR_DATA_TMP "${DIR_PROJ}/data/tmp"

global DIR_SRC_PROCESS "${DIR_PROJ}/src/01_process"
global DIR_SRC_EXPORTS "${DIR_PROJ}/src/02_exports"


do "${DIR_SRC_PROCESS}/gdp.do"
do "${DIR_SRC_PROCESS}/milex.do"
do "${DIR_SRC_PROCESS}/windfalls.do"
do "${DIR_SRC_PROCESS}/panel.do"
