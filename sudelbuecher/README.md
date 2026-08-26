# Sudelb&uuml;cher 

## Janitorial tasks to establish a consistent design flow  

### consolidate xschemrc from different sources into one consistent file  

`diff3 --merge --show-all --label ihp-sg13cmos5l-ams-chip-template --label heichips26-analog-workshop --label sg13cmos5l_ocd_chipalooza ihp-sg13cmos5l-ams-chip-template/macros/inverter/schematic/xschem/xschemrc heichips26-analog-workshop/inverter/schematic/xschem/xschemrc sg13cmos5l_ocd_chipalooza/xschem/xschemrc | tee` [xschemrc.diff3](xschemrc.diff3)  

### [consolidate module directory structure](https://chatgpt.com/share/6a8ec8d1-c6f0-83eb-b186-0812440fa1ae)  
  
commonalities and differences of the recommended directory structures for analog designs/modules in 
[iic-jku/ihp-sg13cmos5l-ams-chip-template](https://github.com/iic-jku/ihp-sg13cmos5l-ams-chip-template) and 
[https://github.com/HeiChips/heichips26-template/tree/main/macros/heichips26_analog_project](https://github.com/HeiChips/heichips26-template/tree/main/macros/heichips26_analog_project) 

Look in [https://heichips.github.io/heichips26-analog-workshop/](https://heichips.github.io/heichips26-analog-workshop/) and 
[iic-jku/analog-circuit-design](https://github.com/iic-jku/analog-circuit-design/) for additional documentation.