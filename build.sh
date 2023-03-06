#!/bin/bash
_EDK2=$PWD/edk2
_EDK2_PLATFORMS=$PWD/edk2-platforms
FLASH=$1

export PACKAGES_PATH=$PWD:$_EDK2:$_EDK2_PLATFORMS
export WORKSPACE=$PWD/workspace

if ! [ -d "${_EDK2}/BaseTools/Source/C/BrotliCompress/brotli/c" ]
then
	git submodule update --init --depth 1
	pushd "${_EDK2}"
	git submodule update --init --depth 1
	popd
fi

shift 1; source "${_EDK2}/edksetup.sh"
[ -d "${WORKSPACE}" ] || mkdir "${WORKSPACE}"
make -j$(nproc) -C "${_EDK2}/BaseTools"|| exit "$?"

GCC5_ARM_PREFIX=arm-none-eabi- build -s -n 0 -a ARM -t GCC5 -b DEBUG -p HtcLeoPkg/HtcLeoPkg.dsc

mkbootimg --base 0x0 --kernel workspace/Build/QSD8250/DEBUG_GCC5/FV/QSD8250_UEFI.fd --kernel_offset 0x10008000 --pagesize 2048 --output uefi.img

if [ "$FLASH" = "--flash" ]
then
	echo "< wait for any device >"
	while ! heimdall detect > /dev/null 2>&1; do
		sleep 1
	done
	heimdall flash --BOOT uefi.img
fi
