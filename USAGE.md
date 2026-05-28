# Squoosh 本地部署使用文档

Squoosh 是 Google 开发的纯客户端图片压缩工具，所有图片处理均在浏览器本地完成，图片数据不会上传到任何服务器。

## 环境要求

- Node.js >= 20.16.0
- npm >= 9.x
- 操作系统：macOS / Linux / Windows

## 快速部署（推荐：一键脚本）

项目提供了一键启动脚本，自动处理依赖安装、构建和启动：

### macOS / Linux

```bash
./start.sh           # 启动（默认端口 3000）
./start.sh 8080      # 指定端口启动
./start.sh stop      # 停止服务
./start.sh status    # 查看运行状态
./start.sh restart   # 重启服务
```

### Windows

```cmd
start.bat            :: 启动（默认端口 3000）
start.bat 8080       :: 指定端口启动
start.bat stop       :: 停止服务
```

启动后访问 `http://localhost:3000` 即可使用。

---

## 手动部署

如需手动操作：

### 1. 安装依赖

```bash
cd /Volumes/Seagate/workspace/code/squoosh
npm ci
```

### 2. 构建生产版本

```bash
npm run build
```

构建产物输出到 `build/` 目录。

### 3. 启动服务

```bash
npx serve build -l 3000
```

启动后访问 `http://localhost:3000` 即可使用。

## 开发模式

如需修改代码并实时预览：

```bash
npm run dev
```

默认在 `http://localhost:5000` 启动开发服务器，支持热更新。

## 功能说明

### 支持的图片格式

| 格式    | 编码（压缩）                | 解码（打开）          |
| ------- | --------------------------- | --------------------- |
| JPEG    | MozJPEG、浏览器原生         | MozJPEG、浏览器原生   |
| PNG     | OxiPNG、浏览器原生          | PNG crate、浏览器原生 |
| WebP    | libwebp（含 SIMD 加速）     | libwebp               |
| AVIF    | libavif + libaom            | libavif               |
| JPEG-XL | libjxl（含多线程 + SIMD）   | libjxl                |
| WebP2   | libwebp2（含多线程 + SIMD） | libwebp2              |
| QOI     | QOI codec                   | QOI codec             |
| GIF     | 浏览器原生                  | 浏览器原生            |

### 主要功能

- **图片压缩**：选择目标格式和质量参数，实时预览压缩效果
- **双栏对比**：左右对比原图和压缩后的图片，支持缩放和平移
- **预处理**：支持旋转、调整尺寸、色彩量化等预处理操作
- **离线使用**：PWA 架构，首次加载后可完全离线使用
- **拖拽/粘贴**：支持拖拽文件、点击选择、从剪贴板粘贴图片

### 操作流程

1. 打开页面，拖入图片或点击选择文件
2. 左侧面板选择压缩格式和参数
3. 右侧实时查看压缩效果和文件大小变化
4. 满意后点击下载按钮保存

## 安全说明

本项目已完成安全审计，已移除所有外部网络通信（Google Analytics）：

- 无数据外泄：图片从不离开浏览器
- 无后门代码：未发现任何恶意代码
- 无挖矿/隐藏任务
- 所有依赖均为知名开源包
- 服务工作者仅拦截同源请求

## 项目结构

```
squoosh/
├── build/              # 构建产物（部署此目录）
├── codecs/             # WASM 编解码器源码
├── lib/                # Rollup 构建插件
├── src/
│   ├── client/         # 浏览器端 UI 代码
│   ├── features/       # 编解码器功能模块
│   ├── shared/         # 共享组件
│   ├── static-build/   # 构建时 SSR 代码
│   └── sw/             # Service Worker
├── package.json
├── rollup.config.js
└── USAGE.md            # 本文档
```

## 常见问题

### Q: 构建时报错 "rollup: command not found"

执行 `npm ci` 安装依赖后再构建。

### Q: 图片处理速度慢

部分编解码器（AVIF、JPEG-XL）计算密集，大图处理需要较长时间。WebP 和 MozJPEG 速度较快。

### Q: 如何重新编译 WASM 编解码器

需要安装 Docker，然后执行：

```bash
cd codecs
./build-cpp.sh    # 编译 C/C++ 编解码器
./build-rust.sh   # 编译 Rust 编解码器
```

### Q: 端口被占用

修改启动命令中的端口号，例如将 `8080` 改为 `3000`：

```bash
npx serve build -l 3000
```

## 许可证

Apache License 2.0
