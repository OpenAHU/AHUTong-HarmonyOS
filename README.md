# 安大通 HarmonyOS

安大通 HarmonyOS 是校园服务应用[安大通 Android 版](https://github.com/OpenAHU/AHUTong)的 HarmonyOS NEXT 迁移项目。项目面向安徽大学校园场景，目标是在 HarmonyOS 上提供与 Android 版一致的核心能力、交互流程和视觉体验，包括统一身份认证、校园卡、电子课表、成绩与考试查询、校园缴费、空闲教室、校历等功能。

> [!IMPORTANT]
> Android 基线中的应用功能已完成 HarmonyOS 源码迁移，并通过本地单元测试及 Debug/Release 构建。真实账号、资金业务、系统权限、逐页视觉和正式签名仍需目标设备与发布材料验收。迁移范围、验证证据和阻塞项统一维护在[迁移文档](docs/MIGRATION.md)中。

## 迁移目标

- **架构一致**：延续 Android 版的 `Core + Data + Feature + App` 分层与按业务域拆分方式。
- **功能一致**：以 Android 版现有行为和数据语义为基准，逐项迁移并验证完整业务流程。
- **UI 一致**：使用 ArkTS 与 ArkUI 复现页面层级、组件语义、配色、间距、圆角、动效以及深浅色表现，并遵循 HarmonyOS 平台交互规范。
- **平台原生**：在保持产品体验一致的前提下，使用 HarmonyOS 原生 Ability、窗口、通知、桌面卡片和数据持久化能力。

## 当前状态

| 项目 | 状态 |
| --- | --- |
| HarmonyOS 基础工程 | 已建立 |
| 迁移基线与功能清单 | 已建立 |
| 分层模块 | Core、Data、Feature 多模块依赖链已建立 |
| 业务功能 | Android 基线的登录、教学、校园生活、工具与设置功能均已实现 |
| 设置与系统能力 | 通知、课表服务卡片、更新检查、Debug/Mock 与灰度能力已迁移 |
| 构建与测试 | 4 个纯逻辑测试模块、Debug HAP、Release HAP 已通过；Release 排除 Debug 字节码 |
| 真机与发布 | 因无设备、测试账号与签名材料，真实接口、资金、视觉、权限和签名验收阻塞 |

详细进度见[《Android 到 HarmonyOS 迁移文档》](docs/MIGRATION.md)。

开发环境、命令行构建、测试、签名和发布检查见[《构建与发布指南》](docs/RELEASE.md)。

## 技术栈

- ArkTS
- ArkUI
- Stage 模型 / UIAbility
- Hvigor
- HarmonyOS SDK 6.1.1（API 24，按当前工程配置）

## 工程结构

当前仓库已建立 `entry` HAP 与 Core、Data、Feature HAR 的基础依赖链，并将按业务域继续扩展：

```text
AHUTong/
├── AppScope/       # 应用级资源与配置
├── entry/          # HAP、UIAbility、导航和模块装配
├── core/           # 公共模型、设计系统、存储、网络与 SDK
├── data/           # 按业务域划分的数据与仓库实现
├── feature/        # 按业务域划分的 ArkUI 页面与状态管理
└── docs/           # 迁移计划、进度和决策记录
```

目录会随迁移提交逐步创建；以[迁移文档](docs/MIGRATION.md)中的架构映射为准。

## 开发约定

- 开发分支：`migration/android-to-harmonyos`
- 每完成一个可独立验收的功能，创建一个符合 Conventional Commits 的提交并立即推送。
- 每个功能提交必须同步更新 `docs/MIGRATION.md`，记录状态、验证结果和必要的差异说明。
- 不提交签名材料、账号凭据、本机配置、依赖目录或构建产物。

## 参考资料

- [安大通 Android 原项目](https://github.com/OpenAHU/AHUTong)
- [HarmonyOS Ability API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ability-api)
- [HarmonyOS NEXT 应用开发实战](https://harmonyos-next.github.io/interview-handbook-project/guide/)
