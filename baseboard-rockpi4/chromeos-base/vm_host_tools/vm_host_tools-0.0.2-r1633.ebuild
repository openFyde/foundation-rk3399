# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="c2cf7c407bb17bb742e5d3992a00ee908425dff2"
CROS_WORKON_TREE=("2345346c6533c29d4e3ee84bc2bf53306247256c" "596301a612265898eb3a71d8393d424d2beec2f8" "55976c0a11bc37a530f8d4c14ae732300e17ccd9" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb" "6568a32dd1e917efc1e269b71e8cda21ba8be9ae" "7ef75a42aba67052842459f221271e681184cc89" "702a5531283ddf1b2b0fdb324430c277afcca358" "dbc0caa5a8069a51f3821099fd9e938ce98205d5" "6e5aa42765227a8ac3316cfc336cd2570cf447ca" "f42c60e5849c89fb552e452019bba6bf9f5defc2" "33df267969e31720f653e84438235d549f958744" "c1a53785c4c668fe9e020912949679cee0f337a6" "e2598f8160f0e1089268ae21cb458eb6bc46d71e" "d59c930e552bd37c28d6a28b36124b8d2413fe7c" "7d583fbeb51de4a6f62f7d6183a76732c3ed85e0" "5b2d971fbeb4e9b96656113119005e6831f2317f" "a1c80f9a557bb4275de2fb9166a814b657fe107a" "4b930736bc7da8c301f27c7a82718e7d605de289" "6a87e586432bf560a19a662dc6b9d3fa89daaf83" "81465f23987dd2c482006411430ef171e856c5fe")
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1

PLATFORM2_PATHS=(
	common-mk
	featured
	metrics
	.gn
	sirenia

	vm_tools/BUILD.gn
	vm_tools/host
	vm_tools/common

	vm_tools/cicerone
	vm_tools/concierge
	vm_tools/dbus
	vm_tools/init
	vm_tools/maitred/client.cc
	vm_tools/pstore_dump
	vm_tools/seneschal
	vm_tools/syslog
	vm_tools/tmpfiles.d
	vm_tools/udev
	vm_tools/vsh

	# Required by the fuzzer
	vm_tools/OWNERS
)
CROS_WORKON_SUBTREE="${PLATFORM2_PATHS[*]}"

PLATFORM_SUBDIR="vm_tools"

inherit tmpfiles cros-workon platform udev user arc-build-constants

DESCRIPTION="VM host tools for Chrome OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools"

LICENSE="BSD-Google"
KEYWORDS="*"
# The crosvm-wl-dmabuf and crosvm-virtio-video USE flags
# are used when preprocessing concierge source.
IUSE="+kvm_host +seccomp +crosvm-wl-dmabuf fuzzer wilco +crosvm-virtio-video vulkan libglvnd crosvm_siblings"
REQUIRED_USE="kvm_host"

COMMON_DEPEND="
	app-arch/libarchive:=
	!!chromeos-base/vm_tools
	chromeos-base/chunnel:=
	chromeos-base/crosvm:=
	>=chromeos-base/metrics-0.0.1-r3152:=
	chromeos-base/minijail:=
	chromeos-base/patchpanel:=
	chromeos-base/patchpanel-client:=
	net-libs/grpc:=
	dev-libs/protobuf:=
"

RDEPEND="
	${COMMON_DEPEND}
	dev-rust/s9
"
DEPEND="
	${COMMON_DEPEND}
	chromeos-base/dlcservice-client:=
	chromeos-base/featured:=
	chromeos-base/manatee-client:=
	chromeos-base/shill-client:=
	chromeos-base/system_api:=[fuzzer?]
	chromeos-base/vm_protos:=
	fuzzer? ( dev-libs/libprotobuf-mutator:= )
"

get_vmlog_forwarder_start_services() {
	local start_services="starting vm_concierge"
	if use wilco; then
		start_services+=" or starting wilco_dtc_dispatcher"
	fi
	echo "${start_services}"
}

get_vmlog_forwarder_stop_services() {
	local stop_services="stopped vm_concierge"
	if use wilco; then
		stop_services+=" and stopped wilco_dtc_dispatcher"
	fi
	echo "${stop_services}"
}

pkg_setup() {
	# Duplicated from the crosvm ebuild. These are necessary here in order
	# to create the daemon-store folder for concierge in src_install().
	enewuser crosvm
	enewgroup crosvm
	enewuser pluginvm
	cros-workon_pkg_setup

	enewuser crosvm-root
	enewgroup crosvm-root
}

src_install() {
	platform_src_install

	dobin "${OUT}"/cicerone_client
	dobin "${OUT}"/concierge_client
	dobin "${OUT}"/maitred_client
	dobin "${OUT}"/seneschal
	dobin "${OUT}"/seneschal_client
	dobin "${OUT}"/vm_cicerone
	dobin "${OUT}"/vm_concierge
	dobin "${OUT}"/vmlog_forwarder
	dobin "${OUT}"/vsh

	if use arcvm; then
		dobin "${OUT}"/vm_pstore_dump
		dobin "${OUT}"/vshd
	fi

	# fuzzer_component_id is unknown/unlisted
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/cicerone_container_listener_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/vsh_client_fuzzer

	# Install header for passing USB devices to plugin VMs.
	insinto /usr/include/vm_concierge
	doins concierge/plugin_vm_usb.h

	insinto /etc/init
	doins init/seneschal.conf
	doins init/vm_cicerone.conf
	doins init/vm_concierge.conf

	dotmpfiles tmpfiles.d/*.conf

	# Modify vmlog_forwarder starting and stopping conditions based on USE flags.
	sed \
		"-e s,@dependent_start_services@,$(get_vmlog_forwarder_start_services),"\
		"-e s,@dependent_stop_services@,$(get_vmlog_forwarder_stop_services)," \
		init/vmlog_forwarder.conf.in | newins - vmlog_forwarder.conf

	insinto /etc/dbus-1/system.d
	doins dbus/*.conf

	insinto /usr/local/vms/etc
	doins init/arcvm_dev.conf

	# TODO(b/159953121): File and steps below should be removed later.
	insinto /etc
	newins init/arcvm_dev.conf_deprecated arcvm_dev.conf

	insinto /usr/share/policy
	if use seccomp; then
		newins "init/vm_cicerone-seccomp-${ARCH}.policy" vm_cicerone-seccomp.policy
	fi

	udev_dorules udev/99-vm.rules

	keepdir /opt/google/vms

	# Create daemon store folder for crosvm and pvm
	local crosvm_store="/etc/daemon-store/crosvm"
	dodir "${crosvm_store}"
	fperms 0700 "${crosvm_store}"
	fowners crosvm:crosvm "${crosvm_store}"

	local pvm_store="/etc/daemon-store/pvm"
	dodir "${pvm_store}"
	fperms 0770 "${pvm_store}"
	fowners pluginvm:crosvm "${pvm_store}"
}

platform_pkg_test() {
	local tests=(
		cicerone_test
		concierge_test
		syslog_forwarder_test
	)
	if use arcvm; then
		tests+=(
			vm_pstore_dump_test
		)
	fi

	# Running a gRPC server under qemu-user causes flake, at least with the
	# combination of gRPC 1.16.1 and qemu 3.0.0. Disable TerminaVmTest.* while
	# running under qemu to avoid triggering this flake.
	# TODO(crbug.com/1066425): Reenable gRPC server tests under qemu-user.
	local qemu_gtest_filter="-TerminaVmTest.*"
	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}" "0" "" "${qemu_gtest_filter}"
	done
}

pkg_preinst() {
	# We need the syslog user and group for both host and guest builds.
	enewuser syslog
	enewgroup syslog

	enewuser vm_cicerone
	enewgroup vm_cicerone

	enewuser seneschal
	enewgroup seneschal
	enewuser seneschal-dbus
	enewgroup seneschal-dbus

	enewuser pluginvm
	enewgroup pluginvm

	enewgroup virtaccess
}

PATCHES=(
	"${FILESDIR}"/reduce_vm_mem.patch
	"${FILESDIR}"/r96_fix_vm_concierge.patch
)
