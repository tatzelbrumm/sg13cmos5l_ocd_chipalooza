# Sudelb&uuml;cher 

## Janitorial tasks to establish a consistent design flow  

### [access chipalooza harness, assigned slot and IO pads](./ocd_chipalooza_digest/README.md)  

### consolidate xschemrc from different sources into one consistent file  

`diff3 --merge --show-all --label ihp-sg13cmos5l-ams-chip-template --label heichips26-analog-workshop --label sg13cmos5l_ocd_chipalooza ihp-sg13cmos5l-ams-chip-template/macros/inverter/schematic/xschem/xschemrc heichips26-analog-workshop/inverter/schematic/xschem/xschemrc sg13cmos5l_ocd_chipalooza/xschem/xschemrc | tee` [xschemrc.diff3](xschemrc.diff3)  

### [consolidate module directory structure](https://chatgpt.com/share/6a8ec8d1-c6f0-83eb-b186-0812440fa1ae)  
  
commonalities and differences of the recommended directory structures for analog designs/modules in 
[iic-jku/ihp-sg13cmos5l-ams-chip-template](https://github.com/iic-jku/ihp-sg13cmos5l-ams-chip-template) and 
[https://github.com/HeiChips/heichips26-template/tree/main/macros/heichips26_analog_project](https://github.com/HeiChips/heichips26-template/tree/main/macros/heichips26_analog_project) 

Look in [https://heichips.github.io/heichips26-analog-workshop/](https://heichips.github.io/heichips26-analog-workshop/) and 
[iic-jku/analog-circuit-design](https://github.com/iic-jku/analog-circuit-design/) for additional documentation.

[ChatGPT](https://chatgpt.com/share/6a8ec8d1-c6f0-83eb-b186-0812440fa1ae), probably assuming `klayout` as the only layout tool (no `magic`) recommends:
```
my_analog_block/
├── README.md
├── Makefile
│
├── schematic/
│   └── xschem/
│       ├── my_analog_block.sch
│       ├── my_analog_block.sym
│       ├── my_analog_block_pex.sym
│       └── xschemrc
│
├── testbenches/
│   └── xschem/
│       ├── my_analog_block_tb_dc.sch
│       ├── my_analog_block_tb_ac.sch
│       ├── my_analog_block_tb_tran.sch
│       ├── xschemrc
│       └── plot_simulations/
│           ├── data/                 # generated
│           ├── figures/              # generated
│           └── plot_my_analog_block.py
│
├── scripts/
│   ├── sizing/
│   │   ├── data/
│   │   ├── figures/
│   │   └── sizing_my_analog_block.ipynb
│   └── ...
│
├── layout/
│   └── my_analog_block.gds
│
├── netlist/                          # generated
│   ├── schematic/
│   ├── layout/
│   └── pex/
│
├── verification/
│   ├── drc/                          # generated results
│   ├── lvs/                          # generated results
│   └── cace/
│       ├── my_analog_block.yaml
│       ├── templates/
│       ├── scripts/
│       └── results/                  # generated
│
└── final/                            # generated integration views
    ├── gds/
    ├── lef/
    ├── lib/
    ├── vh/
    └── render/
```
Then, **only if the block itself is hierarchical**, add:
```
├── macros/
│   ├── bias/
│   ├── ota/
│   └── comparator/
```

### Provide layout infrastructure for both magic and klayout  

* elaborate the `layout` directory structure, to include  
    * both `magic` and `layout`  
    * parametric cells  
    * layout hierarchy  
* consolidate verification (DRC, LvS, PEX) procedures for **both** `magic` and `klayout`

### [Merge and consolidate Makefile](./repo_consolidation.md)  
* [PDF](./repo_consolidation.pdf)  
* [HTML](./repo_consolidation.html)  

