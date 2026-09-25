# 须弥AI

一款简洁流畅的 AI 聊天客户端，灵感来自主流 AI 对话 App（手机端豆包 / 桌面端 Operit 的简洁交互），采用 Flutter 构建。

**包名**：`com.xumitech.ai` · **名称**：须弥AI

## 功能

- 💬 **流式对话**：SSE 流式输出，打字机式逐字渲染，可随时停止生成
- 🔌 **多接口自由切换**：支持任意 OpenAI 兼容 API（Base URL + API Key）
  - 一键「自动获取」该接口的模型列表
  - 同一接口下快速切换模型（顶部下拉）
- 📂 **会话管理**：抽屉侧栏历史会话、新建 / 重命名 / 清空 / 删除
- 🔄 **本地持久化**：接口配置与会话消息全部本地保存，重启不丢失
- 🌗 **多主题**：跟随系统 / 浅色 / 深色

## 配置方法

首次打开进入「设置」→「添加接口」：

| 项 | 说明 |
| --- | --- |
| 名称 | 接口名，如「豆包」「DeepSeek」「自定义」 |
| Base URL | OpenAI 兼容地址，需以 `/v1` 结尾，如 `https://api.example.com/v1` |
| API Key | 你的密钥（Bearer Token） |
| 模型列表 | 可手动填，也可点「自动获取」拉取该接口模型 |

## 架构

```
lib/
├── main.dart                  # 入口 + 主题路由
├── theme/app_theme.dart       # 品牌色 + 全局主题（M3）
├── models/
│   ├── ai_profile.dart        # 接口档案（Base URL/Key/模型）
│   └── chat_conversation.dart # 会话 + 消息模型
├── services/
│   ├── settings_service.dart  # 配置持久化
│   ├── chat_store.dart        # 会话消息持久化
│   └── openai_client.dart     # OpenAI 兼容流式客户端（SSE）
├── provider/app_state.dart    # 全局状态（Provider）
├── screens/
│   ├── chat_screen.dart       # 主聊天页
│   └── settings_screen.dart   # 设置 + 接口档案
└── widgets/
    ├── message_bubble.dart    # 聊天气泡 + 打字指示器
    ├── chat_input_bar.dart    # 输入栏（发送/停止）
    └── conversation_drawer.dart # 会话历史抽屉
```

## 打包 APK（GitHub Actions）

1. 新建 GitHub 空仓库，本地执行：
   ```bash
   cd xumi-ai
   git init -b main && git add . && git commit -m "须弥AI"
   git remote add origin https://github.com/<你>/<仓库>.git
   git push -u origin main
   ```
2. 推送后自动运行 `.github/workflows/build-apk.yml`（生成 android 平台目录、改包名 `com.xumitech.ai`、注入 INTERNET 权限、固定签名、编译拆分 APK）。
3. 到 **Releases → latest-apk** 下载适用于你设备架构的 APK（`app-arm64-v8a` / `app-armeabi-v7a` / `app-x86_64`）。

> 签名固定（同一把 keystore），versionCode 随构建单调递增，可覆盖安装。

## 免责声明

本项目为 AI 聊天客户端工具，本身不含任何模型，所有对话由用户自行配置的第三方 API 接口提供。请遵守相应平台的使用条款与当地法律法规，仅供学习交流使用。生成内容由模型决定，不代表本项目观点。