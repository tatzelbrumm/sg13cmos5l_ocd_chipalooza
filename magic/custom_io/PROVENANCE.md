# Provenance of the custom I/O pad cells

Source repository: https://github.com/tatzelbrumm/sg13cmos5l_cm_ip__single2diff2single
branch `toplevel`, commit `91a7da8b67ac56a26c605501146667a1fde28c32`.

| file here | source path in that commit | sha256 |
|---|---|---|
| `gds/sg13cmos5l_IOPadDiff2Single.gds` | `macros/sg13cmos5l_IOPadDiff2Single/layout/klayout/sg13cmos5l_IOPadDiff2Single.klay.gds` | `13e176ab106d0cb307a6ebc42acf647ce38b6abc52183a9f1d9ffead2f6c2b17` |
| `gds/sg13cmos5l_IOPadSingle2Diff.gds` | `macros/sg13cmos5l_IOPadSingle2Diff/layout/klayout/sg13cmos5l_IOPadSingle2Diff.klay.gds` | `f4b0e07320821248872780b344d71845d08bc250a4bfc9bcf8633a39bdef0182` |

The two `gds/<cell>.gds` files are verbatim copies (sha256 equal to the source).
`gds/<cell>.uniq.gds` are derived by `scripts/custom_io_uniquify.py` (sub-cells renamed with the
prefix `cm_d2s_` resp. `cm_s2d_`, see FINDINGS trap b); the `.mag` files in this directory are
generated from the `.uniq.gds` by `scripts/setup_custom_io.sh` and point to them (`GDS_FILE`).
