#!/usr/bin/env bash
set -e

make -C "$SRC_DIR"/isa RISCV_PREFIX="$CROSS_COMPILE"

# These workloads are not in the NEMU CI workloads on the self hosted runner.
# Although some of them can run on NEMU, some will fail.
# Exclude all of them to be consistant with the original CI flow.
skip_tests=(
    rv64mi-p-access.bin
    rv64mi-p-asid.bin
    rv64mi-p-breakpoint.bin
    rv64mi-p-cbo_clean.bin
    rv64mi-p-cbo_flush.bin
    rv64mi-p-cbo_inval.bin
    rv64mi-p-cbo_zero.bin
    rv64mi-p-csr.bin
    rv64mi-p-illegal.bin
    rv64mi-p-ma_addr.bin
    rv64mi-p-ma_fetch.bin
    rv64mi-p-mcsr.bin
    rv64mi-p-pbmt.bin
    rv64mi-p-sbreak.bin
    rv64mi-p-scall.bin
    rv64mi-p-sfence.bin
    rv64mi-p-svinval.bin
    rv64mi-p-xret_clear_mprv.bin
    rv64mi-p-xtvec.bin
    rv64mi-p-zicntr.bin
    rv64mzicbo-p-zero.bin
    rv64si-p-csr.bin
    rv64si-p-dirty.bin
    rv64si-p-icache-alias.bin
    rv64si-p-immio-af.bin
    rv64si-p-immio.bin
    rv64si-p-ma_fetch.bin
    rv64si-p-satp_ppn.bin
    rv64si-p-sbreak.bin
    rv64si-p-scall.bin
    rv64si-p-wfi.bin
    rv64ssvnapot-p-napot.bin
    rv64uc-p-rvc.bin
    rv64ui-p-ma_data.bin
    rv64uzba-p-add_uw.bin
    rv64uzba-p-sh1add.bin
    rv64uzba-p-sh1add_uw.bin
    rv64uzba-p-sh2add.bin
    rv64uzba-p-sh2add_uw.bin
    rv64uzba-p-sh3add.bin
    rv64uzba-p-sh3add_uw.bin
    rv64uzba-p-slli_uw.bin
    rv64uzbb-p-andn.bin
    rv64uzbb-p-clz.bin
    rv64uzbb-p-clzw.bin
    rv64uzbb-p-cpop.bin
    rv64uzbb-p-cpopw.bin
    rv64uzbb-p-ctz.bin
    rv64uzbb-p-ctzw.bin
    rv64uzbb-p-max.bin
    rv64uzbb-p-maxu.bin
    rv64uzbb-p-min.bin
    rv64uzbb-p-minu.bin
    rv64uzbb-p-orc_b.bin
    rv64uzbb-p-orn.bin
    rv64uzbb-p-rev8.bin
    rv64uzbb-p-rol.bin
    rv64uzbb-p-rolw.bin
    rv64uzbb-p-ror.bin
    rv64uzbb-p-rori.bin
    rv64uzbb-p-roriw.bin
    rv64uzbb-p-rorw.bin
    rv64uzbb-p-sext_b.bin
    rv64uzbb-p-sext_h.bin
    rv64uzbb-p-xnor.bin
    rv64uzbb-p-zext_h.bin
    rv64uzbc-p-clmul.bin
    rv64uzbc-p-clmulh.bin
    rv64uzbc-p-clmulr.bin
    rv64uzbs-p-bclr.bin
    rv64uzbs-p-bclri.bin
    rv64uzbs-p-bext.bin
    rv64uzbs-p-bexti.bin
    rv64uzbs-p-binv.bin
    rv64uzbs-p-binvi.bin
    rv64uzbs-p-bset.bin
    rv64uzbs-p-bseti.bin
    rv64uzfhmin-p-fzfhmincvt.bin
    rv64uzfh-p-fadd.bin
    rv64uzfh-p-fclass.bin
    rv64uzfh-p-fcmp.bin
    rv64uzfh-p-fcvt.bin
    rv64uzfh-p-fcvt_w.bin
    rv64uzfh-p-fdiv.bin
    rv64uzfh-p-fmadd.bin
    rv64uzfh-p-fmin.bin
    rv64uzfh-p-ldst.bin
    rv64uzfh-p-move.bin
    rv64uzfh-p-recoding.bin
)

mkdir -p "$PKG_DIR"/{bin,elf}
for file in "$SRC_DIR"/isa/build/rv64* ; do
    case "$file" in
        *.bin)
            if ! [[ " ${skip_tests[@]} " =~ " $(basename $file) " ]]; then
                cp "$file" "$PKG_DIR"/bin/
            fi
            ;;
        *.dump)
            ;;
        *)
            cp "$file" "$PKG_DIR"/elf/
            ;;
    esac
done
