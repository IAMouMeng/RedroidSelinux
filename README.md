# RedroidSelinux

## Redroid AOSP 修改

### 1. 修改 libselinux 头文件

修改 `external/libselinux/include/selinux.h`：

```c
// #define SE_HACK
// #define se_hack() if (1) return
// #define se_hack1(p) if (1) return p

#undef SE_HACK
#define SE_HACK
#define se_hack() do { } while (0)
#define se_hack1(p) do { (void)sizeof(p); } while (0)
```

### 2. 修改 init 初始化流程

修改 `system/core/init/first_stage_init.cpp`：

```cpp
const char* path = "/system/bin/init";

set_selinuxmnt("/sys/fs/selinux");

std::vector<const char *> args = {path, "second_stage"};
std::string init_cmdline;
android::base::ReadFileToString("/proc/self/cmdline", &init_cmdline);
std::replace(init_cmdline.begin(), init_cmdline.end(), '\0', ' ');
auto cmd_vector = android::base::Split(android::base::Trim(init_cmdline), " ");
int i = 0;
for (const auto& entry : cmd_vector) {
    if (i++ == 0) continue; // ignore first arg '/init'
    args.push_back(entry.c_str());
}
args.push_back(nullptr);
execv(path, const_cast<char**>(args.data()));
// execv() only returns if an error happened, in which case we
// panic and never fall through this conditional.
PLOG(FATAL) << "execv(\"" << path << "\") failed";
```

## 主机开启 SELINUX （可能需要重新编译内核需开启selinux支持）

```shell
# root@orangepi5pro:/# make install_kernel && reboot # 安装内核

root@orangepi5pro:/# apt update && apt install selinux-utils selinux-policy-default policycoreutils setools selinux-policy-dev checkpolicy -y
root@orangepi5pro:/# vim /boot/boot.cmd # setenv bootargs # 后面新增 security=selinux selinux=1 enforcing=0 apparmor=0
root@orangepi5pro:/# mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
root@orangepi5pro:/# reboot
root@orangepi5pro:/# vim /etc/selinux/config # SELINUX=disabled 改成 SELINUX=permissive
root@orangepi5pro:/# reboot
root@orangepi5pro:~# getenforce 
Permissive
```

## 编译安装 android12-dev 规则 等待重启（时间可能较长）
```shell
root@orangepi5pro:/# make build && make install && make relabel
root@orangepi5pro:~# reboot
```

**开机后，使用以下命令实时查看 SELinux 审计日志，补充 policy.conf：**

```shell
tail -f /var/log/audit/audit.log
```

参考来源：https://github.com/SELinuxProject/selinux-notebook