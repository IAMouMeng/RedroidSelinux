# git clone https://android.googlesource.com/platform/system/sepolicy
# cd sepolicy
# git checkout android12-dev

BASE_DIR = /etc/selinux

write_policy:
	m4 -D mls_num_sens=1 \
		-D mls_num_cats=1024 \
		-D target_build_variant=user \
		-D target_recovery=false \
		-s private/security_classes \
		private/initial_sids \
		private/access_vectors \
		public/global_macros \
		public/neverallow_macros \
		private/mls_macros \
		private/mls_decl \
		private/mls \
		private/policy_capabilities \
		public/te_macros \
		public/attributes \
		public/ioctl_defines \
		public/ioctl_macros \
		public/*.te \
		private/*.te \
		private/roles_decl \
		public/roles \
		private/users \
		private/initial_sid_contexts \
		private/fs_use \
		private/genfs_contexts \
		private/port_contexts > policy.conf

build:
	checkpolicy -U allow -c 33 -M -o policy.33 policy.conf

install:
	mkdir -p $(BASE_DIR)/mls-kernel/policy
	mkdir -p $(BASE_DIR)/mls-kernel/contexts/files
	install -m 644 ./policy-files/seusers $(BASE_DIR)/mls-kernel
	install -m 644 ./policy-files/dbus_contexts $(BASE_DIR)/mls-kernel/contexts
	install -m 644 ./policy-files/default_contexts $(BASE_DIR)/mls-kernel/contexts
	install -m 644 ./policy-files/default_type $(BASE_DIR)/mls-kernel/contexts
	install -m 644 ./policy-files/x_contexts $(BASE_DIR)/mls-kernel/contexts
	install -m 644 ./policy-files/file_contexts $(BASE_DIR)/mls-kernel/contexts/files
	install -m 644 policy.33 $(BASE_DIR)/mls-kernel/policy/policy.33
	load_policy

install_kernel:
	dpkg -i ./kernel/*.deb

relabel:
	touch /.autorelabel