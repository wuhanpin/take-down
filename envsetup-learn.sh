1.envsetup.sh 分析

envsetup.sh {
# Execute the contents of any vendorsetup.sh files we can find.
for f in `/bin/ls vendor/*/vendorsetup.sh vendor/*/*/vendorsetup.sh device/*/*/vendorsetup.sh 2> /dev/null`
do
    echo "including $f"
    . $f
done
unset f

addcompletions

}

VARIANT_CHOICES=(user userdebug eng)

function lunch()
{
	local product=$(echo -n $selection | sed -e "s/-.*$//")
	local product=$(mini_arm920t) -userdebug
	export TARGET_BUILD_APPS=
	check_product $product
	function check_product()
	{
		CALLED_FROM_SETUP=true
		BUILD_SYSTEM=build/core
		TARGET_PRODUCT=$1($product)
		TARGET_BUILD_VARIANT=
		TARGET_BUILD_TYPE=
		TARGET_BUILD_APPS=
		get_build_var TARGET_DEVICE > /dev/null
		function get_build_var()
		{
			T=$(gettop)
			CALLED_FROM_SETUP=true
			BUILD_SYSTEM=build/core
			make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-$1
			make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-TARGET_DEVICE

		}
	}
	local variant=$(echo -n $selection | sed -e "s/^[^\-]*-//")
	check_variant $variant
	function check_variant()
	{
		for v in ${VARIANT_CHOICES[@]}	
		return 0
	}
	if [ -z "$product" -o -z "$variant" ];
		return 1
	fi
	export TARGET_PRODUCT=$product
	export TARGET_BUILD_VARIANT=$variant
	export TARGET_BUILD_TYPE=release

	set_stuff_for_environment
	function set_stuff_for_environment()
	{
		settitle
		function settitle()
		{
			local arch=$(gettargetarch)
			local product=$TARGET_PRODUCT
			local variant=$TARGET_BUILD_VARIANT
			local apps=$TARGET_BUILD_APPS
			export PROMPT_COMMAND="echo -ne \"\033]0;[${arch}-${product}-${variant}] ${USER}@${HOSTNAME}: ${PWD}"
		}
		set_java_home
		function set_java_home()
		{
			export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home
			export JAVA_HOME=/usr/lib/jvm/java-6-sun
		}
		setpaths
		function setpaths()
		{
			T=$(gettop)
			export PATH=${PATH/$ANDROID_BUILD_PATHS/}
			export PATH=${PATH/$ANDROID_PRE_BUILD_PATHS/}
			export PATH=${PATH/:%/}

			CODE_REVIEWS=
			prebuiltdir=$(getprebuilt)
			gccprebuiltdir=$(get_abs_build_var ANDROID_GCC_PREBUILTS)
			export ANDROID_EABI_TOOLCHAIN=
			local ARCH=$(get_build_var TARGET_ARCH)
			case $ARCH in
				x86) toolchaindir=x86/i686-linux-android-4.6/bin;;
				arm) toolchaindir=arm/arm-linux-androideabi-4.6/bin;;
				mips) toolchaindir=mips/mipsel-linux-android-4.6/bin;;
				*) toolchaindir=xxxxxxxxx;;
			esac
			export ANDROID_EABI_TOOLCHAIN=$gccprebuiltdir/$toolchaindir
			unset ARM_EABI_TOOLCHAIN ARM_EABI_TOOLCHAIN_PATH
			case $ARCH in
				arm) toolchaindir=arm/arm-eabi-4.6/bin
				export ARM_EABI_TOOLCHAIN="$gccprebuiltdir/$toolchaindir"
				ARM_EABI_TOOLCHAIN_PATH=":$gccprebuiltdir/$toolchaindir"
				mips) toolchaindir=mips/mips-eabi-4.4.3/bin
			esac
			export ANDROID_TOOLCHAIN=$ANDROID_EABI_TOOLCHAIN
			export ANDROID_QTOOLS=$T/development/emulator/qtools
			export ANDROID_DEV_SCRIPTS=$T/development/scripts
			export ANDROID_BUILD_PATHS=$(get_build_var ANDROID_BUILD_PATHS):$ANDROID_QTOOLS:\
					$ANDROID_TOOLCHAIN$ARM_EABI_TOOLCHAIN_PATH$CODE_REVIEWS:$ANDROID_DEV_SCRIPTS:

			export PATH=$ANDROID_BUILD_PATHS$PAT
			unset ANDROID_JAVA_TOOLCHAIN
			unset ANDROID_PRE_BUILD_PATHS
			export ANDROID_JAVA_TOOLCHAIN=$JAVA_HOME/bin
			export ANDROID_PRE_BUILD_PATHS=$ANDROID_JAVA_TOOLCHAIN:
			export PATH=$ANDROID_PRE_BUILD_PATHS$PATH
			unset ANDROID_PRODUCT_OUT
			export ANDROID_PRODUCT_OUT=$(get_abs_build_var PRODUCT_OUT)
			export OUT=$ANDROID_PRODUCT_OUT
			unset ANDROID_HOST_OUT
			export ANDROID_HOST_OUT=$(get_abs_build_var HOST_OUT)
			unset OPROFILE_EVENTS_DIR
			export OPROFILE_EVENTS_DIR=$T/external/oprofile/events

		}
		set_sequence_number
		function set_sequence_number()
		{		
			export BUILD_ENV_SEQUENCE_NUMBER=10
		}
		export ANDROID_BUILD_TOP=$(gettop)
	}

	printconfig
	function printconfig()
	{
		get_build_var report_config
		function get_build_var()
		{
			T=$(gettop)
			$1=report_config
			CALLED_FROM_SETUP=true
			BUILD_SYSTEM=build/core
			make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-$1
		}
	}
}



