# 安大通 Android 到 HarmonyOS 迁移文档

> 最后更新：2026-07-15
>
> 当前分支：`migration/android-to-harmonyos`
>
> 当前阶段：M7 校园生活与缴费（进行中）

本文档是安大通 HarmonyOS 迁移的唯一进度台账。每完成一个可独立验收的功能，必须在同一个提交中更新对应条目、验证结果和变更记录，然后将提交推送到远程迁移分支。

## 1. 目标与验收口径

迁移以 Android 原项目 `E:\OpenAHU\AHUTong` 为产品与行为基准，以当前仓库 `E:\DevEcoStudioProjects\AHUTong` 为 HarmonyOS 实现目录。

“迁移完成”同时满足以下三类一致性：

1. **架构一致**：保留 `Core + Data + Feature + App` 的分层边界、按业务域拆分和单向依赖原则，不要求机械复制 Android API 或文件名。
2. **功能一致**：正常、加载、空数据、失败、登录失效、刷新和缓存等关键状态与 Android 版语义一致。
3. **UI 一致**：页面信息层级、导航、文案、组件、配色、字号、间距、圆角、图标、动效及深浅色表现一致；仅在 HarmonyOS 系统交互有明确要求时采用平台原生表现，并记录差异。

每项功能完成前至少需要：

- 对照 Android 版源代码和可运行界面确认业务流程。
- 完成 ArkTS/ArkUI 实现及必要的资源、权限和平台能力接入。
- 覆盖主要 UI 状态和业务错误路径。
- 通过相关静态检查、测试或真机/模拟器手动验证。
- 更新本文档后，以独立提交推送到远程分支。

## 2. 基线与参考

### 2.1 项目基线

| 类型 | 位置 | 用途 |
| --- | --- | --- |
| Android 原项目 | `E:\OpenAHU\AHUTong` | 产品行为、架构、数据模型与 UI 基准 |
| HarmonyOS 目标项目 | `E:\DevEcoStudioProjects\AHUTong` | 迁移实现 |
| Homogram | `E:\DevEcoStudioProjects\Homogram` | ArkTS/ArkUI、HAP/HAR 与原生层集成参考 |
| localsend-ohos | `E:\DevEcoStudioProjects\localsend-ohos` | HarmonyOS 工程组织与平台适配参考 |

文档建立时的 Android 已提交基线为 `81591c27a94a6249e5449d406ccbda83c25e5b91`，本地分支为 `p/Can4ry/fix/security-module-boundaries`。该工作区同时存在尚未提交的开发改动，这些改动不自动视为迁移基线。开始迁移具体功能时，必须记录所采用的 Android 提交，并明确是否纳入工作区改动，避免迁移基准漂移。

### 2.2 在线资料

- [HarmonyOS Ability API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ability-api)：Ability 生命周期与平台能力的权威 API 基准。
- [HarmonyOS NEXT 应用开发实战](https://harmonyos-next.github.io/interview-handbook-project/guide/)：工程实践参考；若与官方文档冲突，以华为官方文档和当前 SDK 类型定义为准。

### 2.3 当前 HarmonyOS 工程基线

- 应用包名：`com.openahu.ahutong`
- 产品：`default`
- 设备类型：`phone`
- Target / Compatible SDK：HarmonyOS 6.1.1（API 24）
- 当前模块：`entry` HAP，以及 `core_common`、`core_model`、`core_designsystem`、`core_datastore`、`core_network`、`core_sdk_api`、`core_sdk`、`data_auth`、`data_crawler`、`data_schedule`、`data_grade`、`data_exam`、`data_campuscard`、`feature_login`、`feature_home`、`feature_schedule`、`feature_grade`、`feature_exam`、`feature_calendar`、`feature_classroom` HAR
- 当前实现：M1-M3 基础架构已完成；M4 已完成协议门、登录 UI、门户/教务联合登录、安全凭据冷启动恢复、业务请求失效重登及个人学期初始化，仍待真实账号真机验收；M5 已开始迁移教务业务数据链路

## 3. 架构映射

Android 版当前采用 `Core + Data + Feature + App` 多模块架构。HarmonyOS 版保持相同职责和依赖方向，使用 HAP 作为产品入口，使用内部共享模块承载 Core、Data 和 Feature。

```text
entry (HAP / composition root)
  └── feature/*
        └── data/*
              └── core/*
```

禁止反向依赖；Feature 之间不直接共享业务实现，公共能力应下沉到 Core 或对应 Data 域。

| Android 模块 | HarmonyOS 规划模块 | 职责 |
| --- | --- | --- |
| `:app` | `entry` | UIAbility、应用生命周期、导航、主题装配、权限与打包 |
| `:core:common` | `core/common` | 通用结果、会话状态、工具与跨域约定 |
| `:core:model` | `core/model` | 跨层共享的纯业务模型 |
| `:core:designsystem` | `core/designsystem` | ArkUI 主题、设计 token 与统一组件 |
| `:core:datastore` | `core/datastore` | Preferences、缓存与安全存储抽象 |
| `:core:network` | `core/network` | HTTP、Cookie、序列化、错误映射与网络诊断 |
| `:core:sdk-api` / `:core:sdk` | `core/sdk-api` / `core/sdk` | 校园业务 SDK 接口与 HarmonyOS/Native 实现 |
| `:data:*` | `data/*` | auth、schedule、grade、exam、campuscard、portal、payment、calendar、crawler 仓库 |
| `:feature:*` | `feature/*` | 对应业务的 ArkUI 页面、状态与交互 |
| Android Glance Widget | `feature/widget` | HarmonyOS 服务卡片 |
| Android Notification | `feature/notification` | HarmonyOS 通知与提醒调度 |
| Android APK Update | 待决策 | 按 HarmonyOS 分发规则重新设计，不照搬 APK 安装流程 |

状态管理继续遵循 MVVM 思路：ArkUI 页面只消费可观察 UI 状态并派发用户意图；ViewModel/状态持有者编排用例；Repository 隔离远程、缓存和平台实现。

## 4. UI 一致性策略

1. 从 Android `:core:designsystem` 提取 `AhuColors`、`AhuDimens`、字体层级、圆角和通用组件语义，在 `core/designsystem` 建立 ArkUI 等价实现。
2. 页面迁移前保存 Android 基准截图；HarmonyOS 实现对齐相同数据与系统主题后逐页比较。
3. 统一覆盖浅色、深色、正常、加载、空数据、错误、不可用和刷新状态。
4. 导航层级和返回行为与 Android 版保持一致，同时正确处理 HarmonyOS 手势返回、安全区和窗口避让。
5. 平台组件无法像素级复现时，优先保证信息层级和操作语义，并在“已知差异”中记录原因。

建议每个页面保留以下验收证据：Android 基准截图、HarmonyOS 对照截图、验证设备与系统版本、未解决差异。

## 5. 迁移阶段

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| M0 | README、迁移文档、功能与架构基线 | 已完成 |
| M1 | 多模块骨架、依赖规则、测试与构建基线 | 已完成 |
| M2 | Design System、主题、通用页面骨架与导航 | 已完成 |
| M3 | Model、Datastore、Network、SDK 基础能力 | 已完成 |
| M4 | 协议确认、首次启动、登录与会话管理 | 进行中 |
| M5 | 主页、课表、课程详情与周次配置 | 进行中 |
| M6 | 成绩、考试、校历与空闲教室 | 进行中 |
| M7 | 校园卡、电费、浴室与余额充值 | 进行中 |
| M8 | 工具、电话本、失物招领、天气与仓库资源 | 待开始 |
| M9 | 设置、关于、开源许可与数据清理 | 待开始 |
| M10 | 通知、课前提醒、服务卡片及后台任务 | 待开始 |
| M11 | 全量 UI 对照、性能、稳定性、隐私与发布准备 | 待开始 |

阶段只用于组织工作；提交仍按“一个可独立验收的功能”拆分，不把整个阶段压成一个大提交。

## 6. 功能迁移台账

状态取值：`待开始`、`进行中`、`已完成`、`阻塞`、`不适用`。

### 6.1 基础与账户

| 功能 | Android 来源 | HarmonyOS 目标 | 状态 | 验证/备注 |
| --- | --- | --- | --- | --- |
| 四入口主导航 | App / BottomNavBar | `entry` | 已完成 | 主页、课表、工具、设置 Tabs；API 24 Debug HAP 构建通过；无连接设备，待补真机视觉验证 |
| 启动与协议确认 | `feature:login` / Splash | `feature/login` | 已完成 | 免责声明、隐私政策、商业合作依次确认并分别持久化；拒绝即终止 UIAbility；API 24 Debug HAP 构建通过，无连接设备，待补真机视觉与重启持久化验证 |
| 统一身份认证登录 | `feature:login` + `data:auth` | `feature/login` + `data/auth` | 进行中 | 已迁移 UI、状态、Repository、门户验证码/OCR/5 次重试，以及教务 CAS `lt`、设备校验、兼容加密、登录和主页验证；固定向量、无凭据端点及 API 24 构建通过；尚缺真实账号真机端到端验证，故未标记完成 |
| 登录态恢复与失效重登 | `core:common` + `data:auth` | `core/common` + `data/auth` | 进行中 | 已用 Asset Store 安全保存凭据并支持冷启动恢复；教务业务请求统一携带内存 Cookie，识别 401/403 或 CAS 登录页后通过认证仓库重建会话并仅重试一次；API 24 构建通过，因无真实账号和设备尚未完成过期会话运行验收 |
| 个人与学期初始化 | Setup / Info | `feature/login` + `data/schedule` | 已完成 | 登录后缺少配置时显示学年、学期（1/2/3）、当前周初始化页；校验输入、保存用户隔离学年/学期并按当前周反推开学周一；API 24 构建通过，无设备待补交互验证；设置页重新配置入口将在 M9 接入 |

### 6.2 首页与教学服务

| 功能 | Android 来源 | HarmonyOS 目标 | 状态 | 验证/备注 |
| --- | --- | --- | --- | --- |
| 首页与卡片编排 | `feature:home` | `feature/home` | 进行中 | 已迁移日期与当前/下节/今日课程概览、今日课程列表、8 槽位工具网格及课表联动；校园卡、天气真实数据卡待对应数据域迁移；API 24 构建通过，待设备视觉验证 |
| 首页卡片编辑 | `feature:home` | `feature/home` | 进行中 | 支持进入/完成编辑、8 槽位添加与隐藏、上移/下移排序、满槽禁用，以及按用户即时持久化；API 24 构建通过，Android 拖拽手势的 HarmonyOS 触控对照待设备验收 |
| 电子课表 | `feature:schedule` + `data:schedule` | 对应同名域 | 进行中 | 已迁移数据源、用户/学期隔离缓存、20 周切换、回到当前周、强制刷新、星期日期与 1–13 节网格、课程色块及加载/空/错状态；API 24 构建通过，真实课表与视觉仍待账号设备验证 |
| 课程详情 | `feature:schedule` | `feature/schedule` | 进行中 | 点击课程色块显示名称、连续/单双/离散周次、星期与节次、地点、教师，支持遮罩和按钮关闭；API 24 构建通过，待设备交互与视觉验收 |
| 成绩查询 | `feature:grade` + `data:grade` | 对应同名域 | 进行中 | 已迁移多学籍入口识别、各学籍成绩 JSON 聚合、用户缓存、学期筛选、跨学期搜索、GPA/学分摘要、刷新与空错状态，并从首页工具进入；API 24 构建通过，真实账号接口与排名数据待设备验证 |
| 考试查询 | `feature:exam` + `data:exam` | 对应同名域 | 进行中 | 已兼容新版考试表格/座位脚本与旧版 JS 数组，支持用户缓存、课程搜索、刷新、时间状态、地点座位及空错状态，并从首页工具进入；API 24 构建通过，真实页面待账号设备验证 |
| 校历 | `feature:calendar` + `data:calendar` | 对应同名域 | 进行中 | 已迁移 OpenAHU 校历图片加载、系统图片缓存、适应缩放、刷新及加载/失败状态，并从首页工具进入；保存图库与设备缩放手势待平台验收 |
| 空闲教室 | `feature:classroom` | `feature/classroom` | 进行中 | 已迁移磬苑/龙河校区、教学楼多选、1–13 节与上午/下午/晚上快捷选择、今天/明天、全楼/全节默认查询、结果去重排序与空错状态；教务 JSON POST 复用自动重登；API 24 构建通过，任意日期选择器和真实结果待设备验证 |

### 6.3 校园生活与缴费

| 功能 | Android 来源 | HarmonyOS 目标 | 状态 | 验证/备注 |
| --- | --- | --- | --- | --- |
| 校园卡信息与余额 | `data:campuscard` / Home | `data/campuscard` + `feature/home` | 进行中 | 新增门户业务会话客户端与失效重登，迁移 `/xzxcard/yue` 余额与 `/xzxcard/qrcode` 动态校园码；支持余额缓存/刷新、卡片正反切换、码刷新、全屏放大及亮度恢复；API 24 Debug HAP 构建通过，真实余额和动态码待真机账号验证 |
| 校园卡余额充值 | `feature:payment` | `feature/payment` | 待开始 | 金额、确认、结果与重复提交 |
| 电费充值 | `feature:payment` | `feature/payment` | 待开始 | 楼栋、房间、金额与结果 |
| 浴室缴费 | `feature:payment` | `feature/payment` | 待开始 | 账户、金额与结果 |
| 浴室开放信息 | `feature:home` | `feature/home` | 待开始 | 开放状态及异常降级 |
| 失物招领 | `feature:portal` + `data:portal` | 对应同名域 | 待开始 | 列表、加载、刷新与详情入口 |
| 校园电话本 | `feature:tools` | `feature/tools` | 待开始 | 分类、拨号与权限 |
| 天气 | `feature:weather` | `feature/weather` | 待开始 | 当前天气、缓存、失败降级 |

### 6.4 工具与系统能力

| 功能 | Android 来源 | HarmonyOS 目标 | 状态 | 验证/备注 |
| --- | --- | --- | --- | --- |
| 工具页 | `feature:tools` | `feature/tools` | 待开始 | 入口编排与可用状态 |
| 仓库资源与下载 | `feature:repository` | `feature/repository` | 待开始 | 平台下载能力需重新评估 |
| 设置与偏好 | `feature:settings` | `feature/settings` | 待开始 | 主题、课前提醒及业务偏好 |
| 关于、贡献者、开源许可 | `feature:settings` | `feature/settings` | 待开始 | 信息与跳转一致 |
| 清除数据与退出登录 | `feature:settings` | `feature/settings` | 待开始 | 缓存、Cookie、会话完整清理 |
| 课前通知与提醒 | `feature:notification` | `feature/notification` | 待开始 | 权限、调度、点击与重启恢复 |
| 课表服务卡片 | `feature:widget` | `feature/widget` | 待开始 | 尺寸、刷新、点击与数据同步 |
| 应用更新 | `feature:update` | 待定 | 待开始 | 依据 HarmonyOS 分发渠道重新设计 |
| Debug / Mock 工具 | `feature:debug` | `feature/debug` | 待开始 | 仅开发构建启用 |

功能台账若发现缺项，应先补充条目再开始实现；不得因为台账未列出而忽略 Android 已有能力。

## 7. 提交、推送与文档更新规则

每项功能遵循以下闭环：

1. 在开始实现时将对应条目标记为 `进行中`；若这只是准备性改动，可与首个实现提交一起记录。
2. 实现一个可独立验收的纵向功能切片，包括必要的数据、状态、UI、资源和测试。
3. 运行与改动相关的检查、测试或设备验证。
4. 在同一个提交中将台账更新为 `已完成`，填写验证方式，并在“变更记录”追加一行。
5. 使用 Conventional Commits，例如 `feat(schedule): migrate weekly timetable`。
6. 提交后立即推送到 `origin/migration/android-to-harmonyos`。

不得把多个互不相关的业务功能压入同一提交。纯架构、构建、测试或文档改动可独立提交，但仍需在本文档记录其影响。

## 8. 验证矩阵

| 维度 | 最低要求 |
| --- | --- |
| 构建 | 相关模块及 `entry` Debug HAP 构建成功 |
| 静态检查 | ArkTS 编译、Code Linter 无新增错误 |
| 单元测试 | 数据转换、仓库、状态机等可测试逻辑通过 |
| 交互 | 主流程、返回、重复点击、刷新和失败重试通过 |
| UI | 浅色/深色及正常/加载/空/错状态完成对照 |
| 设备 | 记录模拟器或真机型号、系统版本及 API 版本 |
| 数据与安全 | 不记录账号、密码、Cookie、Token 或个人信息 |

若因环境限制无法完成某项验证，必须在功能条目中明确写出未验证范围，不能直接视为通过。

## 9. 已知风险与待决策

- Android 工作区当前可能含未提交改动；每个功能必须锁定源提交和额外差异。
- 校园系统接口、Cookie、WebView 和证书策略需要在 HarmonyOS 网络栈上逐项验证。
- Android 原生 SDK / Rust 或 JNI 能力不能直接假定可用，需要确定 ArkTS、NAPI 或重新实现方案。
- Android 仓库仅含 `arm64-v8a/libahutong_rs.so` 成品而无 Rust 源码，不能直接作为 HarmonyOS NAPI 库复用；当前按业务域迁移 ArkTS 爬虫路径。
- Android 登录成功会缓存智慧安大密码供爬虫自动重登；HarmonyOS 版改用系统 Asset Store，凭据首次解锁后可访问、禁止跨设备同步，且不会进入普通 Preferences。
- 后台任务、开机恢复、通知、课表微件和应用更新均存在平台语义差异，应按 HarmonyOS 官方能力设计。
- UI 一致不等于照搬 Android 系统控件；涉及系统权限、窗口和返回行为时优先满足 HarmonyOS 规范。
- 隐私政策末段的“安卓存储隔离”已按目标平台改为“HarmonyOS 应用数据隔离”，其余协议内容与 Android 基线一致。
- 测试账号、签名文件和线上接口凭据不得进入 Git。

## 10. 变更记录

| 日期 | 类型 | 内容 | 验证 |
| --- | --- | --- | --- |
| 2026-07-14 | 文档 | 建立项目 README、架构映射、迁移阶段、功能台账与提交纪律 | Markdown 链接与仓库状态检查 |
| 2026-07-14 | 架构 | 建立 `core_common → data_schedule → feature_schedule → entry` HAR/HAP 依赖链 | OHPM 依赖同步；API 24 Debug HAP 构建成功 |
| 2026-07-14 | 设计系统 | 新增深浅色语义资源、尺寸与字体 token，以及页面、卡片、标题、按钮、Chip、加载和空状态组件 | 由 `feature_schedule` 实际导入；API 24 Debug HAP 构建成功；待后续页面实机视觉对照 |
| 2026-07-14 | 应用壳 | 替换默认页面，建立与 Android 一致的主页、课表、工具、设置四入口底部 Tabs 和迁移占位页 | API 24 Debug HAP 构建成功；HDC 无连接设备，未执行真机视觉验证 |
| 2026-07-14 | 模型 | 新增 `core_model` HAR，迁移账户、课程、成绩、考试、校园卡、缴费和失物招领等跨层模型及课表数值转换 | 由 `data_schedule` 实际导入；API 24 Debug HAP 构建成功 |
| 2026-07-14 | 存储 | 新增 `core_datastore` HAR，在 UIAbility 启动时初始化 Preferences，迁移用户、协议、学期、课表与显示偏好的按用户隔离缓存 | API 24 Debug HAP 构建成功且无 ArkTS 警告；敏感凭据不写入普通 Preferences |
| 2026-07-14 | 网络 | 新增 `core_network` HAR 与统一 `AppResult`，实现超时、JSON、HTTP/认证错误、主机 Cookie 会话及请求资源释放，并声明 INTERNET 权限 | API 24 Debug HAP 构建成功且无 ArkTS 警告；Cookie 仅驻留内存，待认证层接安全存储 |
| 2026-07-14 | SDK 边界 | 新增 `core_sdk_api` / `core_sdk`，迁移 `CampusNativeGateway` 能力契约、Provider 与明确失败的占位实现 | API 24 Debug HAP 构建成功且无 ArkTS 警告；Rust/JNI 尚未迁移，调用不会伪装成功 |
| 2026-07-14 | 首次启动 | 新增 `data_auth` / `feature_login`，迁移免责声明、隐私政策与商业合作三段顺序确认、本地持久化和拒绝退出，并接入应用入口 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；无签名及连接设备，未执行安装、视觉和冷启动验证 |
| 2026-07-14 | 登录界面与状态 | 对照 Android 恢复账号/密码胶囊输入、四张焦点表情、密码显隐与动态登录状态条；新增可注入认证 Repository、会话门和成功用户持久化 | API 24 Debug HAP 构建成功且无 ArkTS 警告；原生 SDK 当前明确返回不可用，未使用假成功，真实账号认证待后续数据源提交 |
| 2026-07-14 | 门户认证数据源 | 新增 `data_crawler`，迁移安大门户验证码、OpenAHU OCR、表单登录、Cookie 会话与 5 次验证码重试；认证仓库在 Native 不可用时自动降级到该真实数据源 | 验证码端点返回 200 和会话 Cookie，OCR 返回 4 位结果；API 24 Debug HAP 构建成功且无 ArkTS 警告；未使用或记录真实账号，教务 CAS 会话仍待迁移 |
| 2026-07-14 | 教务 CAS 认证 | 忠实移植 Android `DES.strEnc` 兼容算法，新增多 Cookie 内存会话、CAS `lt` 提取、设备校验、登录重定向和教务主页登录态验证，并与门户登录串联 | ArkTS 加密结果与 Android 固定向量完全一致；匿名访问最终到达 CAS 页面、返回 45 字符 `lt` 及 3 个 Cookie；API 24 Debug HAP 构建成功且无 ArkTS 警告；缺真实账号真机验证 |
| 2026-07-14 | 安全凭据与冷启动恢复 | 新增 Asset Store 凭据封装；登录成功后安全保存账号密码，冷启动用凭据重建门户/CAS Cookie，会话恢复失败时清除缓存用户并回到登录页，退出时删除安全资产 | API 24 Debug HAP 构建成功且无 ArkTS 警告；Asset Store 与冷启动流程因无设备未做运行验证，业务请求会话过期自动重登待后续仓库接入 |
| 2026-07-14 | 个人与学期初始化 | 迁移 Android `Info` 页面，新增学年、1/2/3 学期、当前周输入与校验；按用户保存标准学期键，并依据当前日期和周次反推、保存开学周一 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；无连接设备，未执行输入法和视觉验证 |
| 2026-07-14 | 教务会话失效重登 | 新增教务业务请求客户端，统一携带内存 Cookie，识别 HTTP 认证错误及 CAS 登录页；会话失效时从 Asset Store 凭据重建门户/教务会话并限次重试 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；无真实账号与连接设备，失效重登待运行验证 |
| 2026-07-14 | 课表数据源与缓存 | 迁移 Android 课表爬虫与仓库：解析教务当前学期脚本、请求 `print-data`、映射课程周次/星期/节次/教师/教室，并按用户和学期缓存及支持强制刷新 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；匿名请求仅能验证认证防线，真实课程数据待账号设备验收 |
| 2026-07-14 | 电子周课表 | 以 ArkUI 迁移 Android 课表主界面：20 周胶囊选择、当前周定位、刷新、星期日期表头、1–13 节纵轴、按周过滤课程色块，以及加载、空数据和失败重试状态 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；无真实账号和连接设备，待课程重叠与深浅色视觉对照 |
| 2026-07-14 | 课程详情 | 为课程色块接入详情弹层，展示课程名称、连续/单双/离散周次、星期、节次、地点和教师，并支持点击遮罩或按钮关闭 | API 24 Debug HAP 构建成功且无 ArkTS 警告；无连接设备，待触控与深浅色视觉对照 |
| 2026-07-14 | 首页课程与卡片骨架 | 新增 `feature_home`，迁移日期、当前/下节/今日课程概览、今日课程列表、8 槽位工具网格，并以真实课表缓存驱动当前周和当日过滤，点击课程区域切换到课表 Tab | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；校园卡与天气仍为后续数据切片，无连接设备待视觉验证 |
| 2026-07-14 | 首页卡片编辑 | 迁移 8 槽首页工具配置，支持显式编辑、添加、隐藏、上移/下移排序、满槽控制及用户隔离即时持久化；空槽与删除态提供视觉反馈 | API 24 Debug HAP 构建成功且无 ArkTS 警告；当前以可访问按钮排序替代拖拽，待设备验证长按/拖拽是否需要补齐 |
| 2026-07-14 | 成绩查询 | 新增 `data_grade` / `feature_grade`，迁移多学籍识别、成绩 JSON 转换与加权 GPA 聚合、用户缓存、学期筛选、跨学期搜索、摘要和成绩卡片，并接入首页成绩工具路由 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；无真实账号与连接设备，学籍 HTML、成绩接口及排名数据待运行验收 |
| 2026-07-14 | 考试查询 | 新增 `data_exam` / `feature_exam`，兼容新版 `tr[data-finished]` 表格与座位脚本、旧版 `studentExamInfoVms`，实现用户缓存、搜索、刷新、考试状态、地点和座位展示，并接入首页考场工具路由 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；无真实账号与连接设备，两种线上 HTML 格式待运行验收 |
| 2026-07-14 | 校历 | 新增 `feature_calendar`，接入 OpenAHU 校历图片，支持系统图片缓存、适应缩放、强制刷新、加载和失败重试，并接入首页校历工具路由 | API 24 Debug HAP 构建成功后记录；无连接设备，保存图库与缩放手势仍待平台验收 |
| 2026-07-15 | 空闲教室 | 扩展教务客户端 JSON POST 与会话失效重试；新增 `feature_classroom`，迁移校区、教学楼、节次分组、今天/明天筛选、逐楼查询、结果去重排序与首页工具路由 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；无真实账号与连接设备，接口结果及任意日期选择待运行验收 |
| 2026-07-15 | 校园卡余额 | 新增门户业务请求客户端及 Asset Store 凭据失效重登钩子；新增 `data_campuscard`，迁移余额获取和用户缓存，并在首页恢复余额卡、刷新与错误状态 | OHPM 全模块依赖同步；API 24 Debug HAP 构建成功且无 ArkTS 警告；无真实账号与连接设备，门户余额及过期重登待运行验收 |
| 2026-07-15 | 动态校园码 | 迁移 `/xzxcard/qrcode` 成功码与载荷校验，使用 ArkUI 原生 `QRCode` 渲染可扫码图形；首页卡片支持余额/校园码切换、点击刷新、全屏放大，并在关闭或离页时恢复原窗口亮度 | API 24 Debug HAP 构建成功且无 ArkTS 警告；无真实账号与连接设备，码内容、扫码成功率及亮度恢复待真机验收 |
