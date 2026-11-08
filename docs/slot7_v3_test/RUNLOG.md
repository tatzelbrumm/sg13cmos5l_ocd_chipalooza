# Slot 7 v3 harness test (2026-11-08/09)

Request: the slot7 hand-over session (session_01XU3KH77upRZxPAr9FvWL5j), confirmed by the user: "yes, go ahead with 1-2 and the
slot-7 DRC", then make the new main available to Tim if it does not break his flow, then full-chip fill and top LVS.
Fork `tatzelbrumm/sg13cmos5l_ocd_chipalooza`, branch `claude/slot7-v3-harness-test`, from `claude/slot7-v2-harness-test`
04065d7 (Tim ff68060 + patches 0001-0004 + regenerated views + Verilog edits). Clone `/home/user/v2test`.
Only change in the harness input: `config.txt` `s7_version: main 158afc5afab0056bd6d216a4db3833e34a364949`
(sg13cmos5l_cm_slot7 main = slot 7 v3 + tughra art). Note: Tim's own `config.txt` has `s7_version: - -`, i.e. his
`make projects` takes whatever slot7 `main` is: v3 is live for Tim since 158afc5 was pushed.
Logged with `docs/slot7_v3_test/run.sh` (stdout/stderr teed to `logs/NN_name.{out,err}`).

## Journal
- 01 (first try) `make projects-update` without SLOTS started cloning every slot of config.txt (slots 1-14 cloned, 1.2 GB, slot 9 alone 828 MB) before I stopped it (not asked for: the user asked only about the cost of an all-slots test). Clones removed (dependencies/slot_N, .git/modules, .gitmodules restored); slot 7 was already on 158afc5. Rerun as `make projects-update SLOTS=7`.

### 01 make_projects-update_SLOTS=7
- start 2026-11-08T23:55:52Z, end 2026-11-08T23:55:53Z
- cwd: `/home/user/v2test`
- command: `make projects-update SLOTS=7`
- exit status: 0
- logs: `logs/01_make_projects-update_SLOTS=7.out`, `logs/01_make_projects-update_SLOTS=7.err`

### 02 make_setup-custom
- start 2026-11-08T23:55:53Z, end 2026-11-08T23:55:56Z
- cwd: `/home/user/v2test`
- command: `make setup-custom`
- exit status: 0
- logs: `logs/02_make_setup-custom.out`, `logs/02_make_setup-custom.err`

### 03 make_clean-config
- start 2026-11-08T23:55:56Z, end 2026-11-08T23:55:56Z
- cwd: `/home/user/v2test`
- command: `make clean-config`
- exit status: 0
- logs: `logs/03_make_clean-config.out`, `logs/03_make_clean-config.err`

### 04 make_config
- start 2026-11-08T23:55:56Z, end 2026-11-08T23:55:56Z
- cwd: `/home/user/v2test`
- command: `make config`
- exit status: 0
- logs: `logs/04_make_config.out`, `logs/04_make_config.err`

### 05 make_padframe
- start 2026-11-08T23:55:56Z, end 2026-11-08T23:56:05Z
- cwd: `/home/user/v2test`
- command: `make padframe`
- exit status: 0
- logs: `logs/05_make_padframe.out`, `logs/05_make_padframe.err`

### 06 make_frame-custom-io
- start 2026-11-08T23:56:05Z, end 2026-11-08T23:56:06Z
- cwd: `/home/user/v2test`
- command: `make frame-custom-io`
- exit status: 0
- logs: `logs/06_make_frame-custom-io.out`, `logs/06_make_frame-custom-io.err`

### 07 make_wrappers
- start 2026-11-08T23:56:06Z, end 2026-11-08T23:56:09Z
- cwd: `/home/user/v2test`
- command: `make wrappers`
- exit status: 0
- logs: `logs/07_make_wrappers.out`, `logs/07_make_wrappers.err`

### 08 make_gds-slots
- start 2026-11-08T23:56:09Z, end 2026-11-08T23:56:09Z
- cwd: `/home/user/v2test`
- command: `make gds-slots`
- exit status: 0
- logs: `logs/08_make_gds-slots.out`, `logs/08_make_gds-slots.err`

### 09 make_user-id
- start 2026-11-08T23:56:09Z, end 2026-11-08T23:56:10Z
- cwd: `/home/user/v2test`
- command: `make user-id`
- exit status: 0
- logs: `logs/09_make_user-id.out`, `logs/09_make_user-id.err`

### 10 make_projects-gds_SLOTS=7
- start 2026-11-08T23:56:10Z, end 2026-11-08T23:56:19Z
- cwd: `/home/user/v2test`
- command: `make projects-gds SLOTS=7`
- exit status: 0
- logs: `logs/10_make_projects-gds_SLOTS=7.out`, `logs/10_make_projects-gds_SLOTS=7.err`
