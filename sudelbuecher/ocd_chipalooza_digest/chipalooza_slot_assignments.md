# Chipalooza Challenge #2 slot assignments

The designer and circuit assignments below are transcribed from the table supplied in this chat. The slot numbers and dedicated-pin counts agree with the [harness and pinout diagram](https://github.com/RTimothyEdwards/sg13cmos5l_ocd_chipalooza/blob/main/doc/sg13cmos5l_chipalooza_harness_64pin.pdf). A public source for the designer assignments has not been identified.

| Slot | Dedicated pins | Designer | Circuit |
| ---: | ---: | --- | --- |
| 1 | 2 | Araujo | Level shifter |
| 2 | 2 | Saab | CDR |
| 3 | 2 | Hubai | HSXO |
| 4 | 1 | Ridha | Window comparator |
| 5 | 3 | Sotehi | High GBW op amp |
| 6 | 2 | Mysore | PLL |
| 7 | 2 | Maier | Differential ↔ single-ended drivers |
| 8 | 1 | Kvitschal | CMOS voltage reference |
| 9 | 3 | Malik et al. | Instrumentation amp |
| 10 | 3 | Rodovalho | Low-power op amp |
| 11 | 1 | Mysore | Capless LDO |
| 12 | 2 | Mahmoud | 2.5 GHz LNA |
| 13 | 2 | Unassigned | May be used for extra pins by slot 14 |
| 14 | 3 | Bhagwat/Schackenberg | PLL + LVDS |
| 15 | 1 | Rout | Bandgap |
| 16 | 2 | Yu/Ananth/Olonade | 12-bit SAR ADC |
| 17 | 2 | Brahim | Voltage supervisor |
| 18 | 2 | Jones | LC tank VCO |

The [harness `config.txt`](https://github.com/RTimothyEdwards/sg13cmos5l_ocd_chipalooza/blob/main/config.txt) names each slot's dedicated pad signals (`s1_an` through `s18_an`).
