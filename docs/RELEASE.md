# 构建与发布指南

本文用于复现安大通 HarmonyOS 的依赖安装、测试、构建与发布流程。迁移功能和验收状态见[迁移文档](MIGRATION.md)。

## 环境

- DevEco Studio 与 HarmonyOS SDK 6.1.1（API 24）
- 工程随 DevEco Studio 提供的 Node.js、OHPM 与 Hvigor
- Windows PowerShell（下列命令以项目根目录为工作目录）

首次构建前，将工具目录加入当前终端环境。安装位置按本机 DevEco Studio 路径调整：

```powershell
$env:NODE_HOME='E:\Huawei\DevEco Studio\tools\node'
$env:DEVECO_SDK_HOME='E:\Huawei\DevEco Studio\sdk'
$env:Path='E:\Huawei\DevEco Studio\tools\node;E:\Huawei\DevEco Studio\tools\ohpm\bin;E:\Huawei\DevEco Studio\tools\hvigor\bin;' + $env:Path
ohpm install --all
```

## 构建与测试

```powershell
# Debug HAP
hvigorw --mode module -p module=entry@debug -p product=default -p requiredDeviceType=phone -p buildMode=debug assembleHap

# Release HAP
hvigorw --mode module -p module=entry@release -p product=default -p requiredDeviceType=phone -p buildMode=release assembleHap

# 当前纯逻辑测试模块
hvigorw -p module=core_common@default test
hvigorw -p module=core_model@default test
hvigorw -p module=data_crawler@default test
hvigorw -p module=feature_update@default test
```

测试报告位于各模块的 `.test/default/outputs/test/reports`。设备交互、系统授权、服务卡片和真实校园接口需在 DevEco Studio 中连接 HarmonyOS 设备验收。

## Release 策略

- Release 启用 ArkTS 压缩并移除 `console.*` 日志。
- 不混淆属性名、导出名与文件名，避免改变校园接口 JSON 字段及 HAR 公共 API。
- 调整 `AppScope/app.json5` 的 `versionCode` 与 `versionName`，两者必须随正式版本递增。
- 正式发布前在本机 DevEco Studio 配置签名。证书、Profile、私钥和密码不得提交到仓库。
- 构建后在至少一台目标设备执行首次启动、登录恢复、四个主入口、权限拒绝/允许、深浅色及退出清理冒烟测试。

## 发布检查清单

1. 工作树干净，目标提交已推送到 `migration/android-to-harmonyos`。
2. 全部纯逻辑测试、Debug HAP 与 Release HAP 构建通过。
3. 使用测试账号完成课表、成绩、考试、校历、空闲教室与校园卡只读流程。
4. 仅在授权测试账户和可控金额下验收校园卡、电费、浴室支付；核对订单状态后再扩大测试。
5. 验证通知授权与触发、课表服务卡片两种尺寸、天气定位和图库保存。
6. 对照 Android 版逐页检查文本、间距、颜色、滚动、键盘和返回行为。
7. 配置正式签名，安装签名后的 Release HAP 并完成升级与数据保留测试。
8. 创建 GitHub Release；如需强制更新，在发行说明中加入 `<!-- ahutong-force-update -->`。
9. 同步应用市场版本与发行说明，复核隐私声明、权限用途和支持链接。

未取得签名材料、测试账号或目标设备时，不得把对应验收项标记为已完成。
