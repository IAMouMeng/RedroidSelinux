checkpolicy -U allow -c 33 -M -o mls_policy.33 policy.conf
install -m 644 mls_policy.33 /etc/selinux/nb-mls-kernel/policy/policy.33
# touch /.autorelabel
load_policy
