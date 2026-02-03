# Dria Compute Node Installer

这个仓库包含了一个用于 macOS 的 Dria 计算节点一键安装和优化脚本。

## 功能

- 自动检测并安装 Ollama (如果未安装)
- 自动检测并安装 Dria Compute Launcher
- 自动配置环境变量 (zsh/bash)
- 创建桌面启动快捷方式，方便日后启动
- 网络连接检查与错误处理

## 快速安装

使用以下命令一键安装：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Xiaofei-Z/deploy_nodes/main/Dria/install_dria.sh)
```

## 手动安装

1. 克隆仓库:
   ```bash
   git clone https://github.com/Xiaofei-Z/deploy_nodes.git
   ```
2. 进入目录:
   ```bash
   cd deploy_nodes/Dria
   ```
3. 运行脚本:
   ```bash
   chmod +x install_dria.sh
   ./install_dria.sh
   ```

## 包含文件

- `install_dria.sh`: 主安装脚本
