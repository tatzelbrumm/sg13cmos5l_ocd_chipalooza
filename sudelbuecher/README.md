# Sudelb&uuml;cher 

## Janitorial tasks to establish a consistent design flow  

### consolidate xschemrc from different sources into one consistent file  

`diff3 --merge --show-all --label ihp-sg13cmos5l-ams-chip-template --label heichips26-analog-workshop --label sg13cmos5l_ocd_chipalooza ihp-sg13cmos5l-ams-chip-template/macros/inverter/schematic/xschem/xschemrc heichips26-analog-workshop/inverter/schematic/xschem/xschemrc sg13cmos5l_ocd_chipalooza/xschem/xschemrc | tee` [xschemrc.diff3](xschemrc.diff3)  