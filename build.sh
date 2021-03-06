#!/bin/bash
# This is generic build script we generated for our use case.
. setup_env

arg="$1"

function print_help () {
	echo "####################################################"
	echo "To build complete buildroot and generate rootfs.tar"
	echo "sudo ./build.sh all"
	echo ""
	echo "To rebuild linux with updated changes"
	echo "sudo ./build.sh linux"
	echo ""
	echo "To rebuild uboot with updated changes"
	echo "sudo ./build.sh uboot"
	echo ""
	echo "To create lubuntu filesys"
	echo "sudo ./build.sh lubuntu"
	echo ""
	echo "To clean all the directories"
	echo "sudo ./build.sh distclean"
	echo "WARNING: Above command will delete all the " \
	"downlaoded packages and restart all the things from " \
        "scratch"
	echo ""
	echo "To get help of build script commands"
	echo "sudo ./build.sh help"
	echo "####################################################"
}

function get_toolchain() {
	if [ ! -d $DOWNLOAD_DIR ]
	then
		mkdir -p $DOWNLOAD_DIR
		cd $DOWNLOAD_DIR
		wget https://github.com/Rhomb-io/common-packages-rhomb/releases/download/1.0.0/exynos_arm_toolchain.tgz
	elif [ -d $DOWNLOAD_DIR ]
	then
		if [ ! -f $DOWNLOAD_DIR/exynos_arm_toolchain.tgz ]
		then
			cd $DOWNLOAD_DIR
			wget https://github.com/Rhomb-io/common-packages-rhomb/releases/download/1.0.0/exynos_arm_toolchain.tgz
		fi
	fi
}

function export_toolchain () {
	if [ -d $TOOLCHAIN_DIR ];
	then
	export PATH=$PATH:/$TOOLCHAIN_DIR
	else
		get_toolchain
		mkdir -p $TOOLCHAIN_DIR
		cd $TOOLCHAIN_DIR
		tar -zxvf $DOWNLOAD_DIR/exynos_arm_toolchain.tgz
		export PATH=$PATH:/$TOOLCHAIN_DIR
		cd $ROOT_DIR
	fi
}

function linux_install () {
	mkdir -p $IMAGES_DIR
	cat $KERNEL_DIR/arch/arm/boot/zImage $KERNEL_DIR/arch/arm/boot/dts/exynos4412-rhomb-expansion.dtb > $IMAGES_DIR/zImage
	cd $KERNEL_DIR
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- modules_install INSTALL_MOD_PATH=$FILESYSTEM_DIR
	mkdir -p $FILESYSTEM_DIR/lib/firmware/edid
	cp $KERNEL_DIR/Documentation/EDID/1920x1080.bin $FILESYSTEM_DIR/lib/firmware/edid/
	cd $ROOT_DIR
}

function linux_rebuild () {
        cd $KERNEL_DIR
        make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- distclean
        make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- rhomb_gaia_defconfig
        make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- zImage -j4
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- modules
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- exynos4412-rhomb-expansion.dtb
	cd $KERNEL_DIR/Documentation/EDID
	make clean
	make all
        cd $ROOT_DIR
}

function linux_build () {
	export_toolchain
	if [ -d $KERNEL_DIR ];
	then
		cd $KERNEL_DIR
		sudo git pull
		linux_rebuild
		linux_install
	else
		git clone https://github.com/Rhomb-io/Exynos4412-4.8-Rhomb.git $KERNEL_DIR
		linux_rebuild
		linux_install
	fi
}

function uboot_install () {
	mkdir -p $IMAGES_DIR
	mkdir -p $FILESYSTEM_DIR/etc
	cp $UBOOT_DIR/u-boot.bin $IMAGES_DIR/
	cp $UBOOT_DIR/tools/env/fw_env.config $FILESYSTEM_DIR/etc/
        cp $UBOOT_DIR/sd_fuse/bl1.HardKernel $IMAGES_DIR/
        cp $UBOOT_DIR/sd_fuse/bl2.HardKernel $IMAGES_DIR/
        cp $UBOOT_DIR/sd_fuse/tzsw.HardKernel $IMAGES_DIR/
        cp $UBOOT_DIR/sd_fuse/sd_fusing.sh $IMAGES_DIR/
}

function uboot_rebuild () {
	cd $UBOOT_DIR
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- distclean
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- rhomb_gaia_config
	make ARCH=arm CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-none-linux-gnueabi- u-boot.bin -j4
	cd $ROOT_DIR
}

function uboot_build () {
	export_toolchain
	if [ -d $UBOOT_DIR ];
	then
		cd $UBOOT_DIR
		sudo git pull
		uboot_rebuild
		uboot_install
	else
		git clone https://github.com/Rhomb-io/u-boot-rhomb.git $UBOOT_DIR
		uboot_rebuild
		uboot_install
	fi
}

function build_lubuntu () {
	rm -rf $IMAGES_DIR/lubuntu.tgz
	sudo cp $FILESYSTEM_DIR/* $LUBUNTU_DIR/ -rf
	cd $LUBUNTU_DIR
	sudo tar -cvzf $IMAGES_DIR/lubuntu.tgz *
	sync
	cd $ROOT_DIR
}

function get_lubuntu () {
	if [ ! -d $DOWNLOAD_DIR ]
	then
		mkdir -p $DOWNLOAD_DIR
		cd $DOWNLOAD_DIR
		wget https://github.com/Rhomb-io/lubuntu-rhomb/releases/download/1.0.0/lubuntu_rhomb_base_14_04_5.tgz
		wget https://github.com/Rhomb-io/lubuntu-rhomb/releases/download/1.0.1/lib.tgz
		wget https://github.com/Rhomb-io/lubuntu-rhomb/releases/download/1.0.2/share.tgz
	elif [ -d $DOWNLOAD_DIR ]
	then
		if [ ! -f $DOWNLOAD_DIR/lubuntu_rhomb_base_14_04_5.tgz ]
		then
			cd $DOWNLOAD_DIR
			wget https://github.com/Rhomb-io/lubuntu-rhomb/releases/download/1.0.0/lubuntu_rhomb_base_14_04_5.tgz
		fi
		if [ ! -f $DOWNLOAD_DIR/lib.tgz ]
		then
			cd $DOWNLOAD_DIR
			wget https://github.com/Rhomb-io/lubuntu-rhomb/releases/download/1.0.1/lib.tgz
		fi
		if [ ! -f $DOWNLOAD_DIR/share.tgz ]
		then
			cd $DOWNLOAD_DIR
			wget https://github.com/Rhomb-io/lubuntu-rhomb/releases/download/1.0.2/share.tgz
		fi
	fi
	cd $BUILD_DIR
	mkdir -p $LUBUNTU_DIR
	cd  $LUBUNTU_DIR
	sudo tar -zxvf $DOWNLOAD_DIR/lubuntu_rhomb_base_14_04_5.tgz
	cd $LUBUNTU_DIR/usr
	sudo tar -zxvf $DOWNLOAD_DIR/lib.tgz
	sudo tar -zxvf $DOWNLOAD_DIR/share.tgz
	sync
}

function lubuntu_build () {
	if [ -d $LUBUNTU_DIR ]
	then
		build_lubuntu
	else
		get_lubuntu
		build_lubuntu
	fi
}

function all_dir_clean () {
	rm -rf $ROOT_DIR/output
	rm -rf $ROOT_DIR/dl
}

case $arg in
	"linux")
		linux_build
	;;
	"uboot")
		uboot_build
	;;
	"lubuntu")
		lubuntu_build
	;;
	"all")
		uboot_build
		linux_build
		lubuntu_build
	;;
	"distclean")
		all_dir_clean
	;;
	"help")
		print_help
	;;
	*)
		print_help

	;;
esac

