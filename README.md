# RedroidSelinux

## 项目简介

本项目用于在 Redroid 上启用 SELinux 支持。通过修改 Android 源码和配置 SELinux 策略，使 Redroid 容器能够正常运行在启用 SELinux 的主机环境中。

## 前置要求

- 确保主机已启用 SELinux 并开启 Permissive 模式
- 了解 SELinux 基本概念

## 配置步骤

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

### 3. 整合 SELinux 规则

参考 [Android SELinux Policy Makefile][1]，整合 SELinux 规则。

**重要**：编译时需要修改命令为：

```bash
checkpolicy -U allow -c 33 -M -o sepolicy policy.conf
```

将整合好的规则填充到 Linux 的 policy 中，并修改 Linux policy 域为 `kernel`。

### 4. 设置 kernel 域为宽容模式

在策略中添加：

```
permissive kernel;
```

> **注意**：将 kernel 域单独设置为宽容模式，可以防止前面步骤配置不当导致无法开机。

### 5. 配置 MLS 策略

参考 [SELinux Kernel Policy Makefile][2] 中的 `install_mls_policy` 部分。

修改 MLS 中的 `default_contexts` 等配置为 `u:r:kernel:s0` 并安装。

### 6. 修改 SELinux 配置

修改 `/etc/selinux/config` 中的 target 为 `nb-mls-kernel`。

### 7. 重启系统

```bash
reboot
```

## 后续调试

重启后，通过 `dmesg` 查看 SELinux 相关日志，根据拒绝信息逐步完善 policy 规则。

## 注意事项

- 本配置目前可以正常开机，但在强制模式下仍存在一些小问题
- 建议先在 Permissive 模式下测试稳定后，再考虑切换到 Enforcing 模式
- 请根据实际情况调整策略规则

## 参考资料

[1]: https://github.com/SELinuxProject/selinux-notebook/blob/main/src/notebook-examples/embedded-policy/android-policy/android-10/Makefile
[2]: https://github.com/SELinuxProject/selinux-notebook/blob/main/src/notebook-examples/selinux-policy/kernel/Makefile

- [Android SELinux Policy 示例][1]
- [SELinux Kernel Policy 示例][2]