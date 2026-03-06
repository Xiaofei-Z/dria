#!/bin/bash

# ==========================================
# Dria & Ollama 一键安装与优化脚本
# ==========================================

# 设置颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 辅助日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 错误处理
handle_error() {
    log_error "发生错误，脚本终止。错误行号: $1"
    exit 1
}
trap 'handle_error $LINENO' ERR

# 检查架构并设置兼容模式
ARCH_PREFIX=""
if [[ "$(uname -m)" == "arm64" ]]; then
    log_warn "检测到 Apple Silicon (M1/M2/M3...) 芯片"
    log_info "将使用 Rosetta 2 (x86_64) 模式运行以避免兼容性问题"
    ARCH_PREFIX="arch -x86_64"
    
    # 检查 Rosetta 2 是否安装
    if ! pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto > /dev/null 2>&1; then
        log_info "正在安装 Rosetta 2..."
        softwareupdate --install-rosetta --agree-to-license
    fi
fi

# 检查网络连接
check_network() {
    log_info "正在检查网络连接..."
    if curl -s --head  --request GET https://www.google.com | grep "200 OK" > /dev/null; then 
        log_success "网络连接正常"
    else
        log_warn "无法连接到 Google，可能影响下载，尝试继续..."
    fi
}

# 安装 Ollama
install_ollama() {
    if [ -d "/Applications/Ollama.app" ]; then
        log_success "Ollama 已安装，跳过安装"
    else
        log_info "正在下载 Ollama..."
        TEMP_DMG=$(mktemp /tmp/Ollama.XXXXXX.dmg)
        curl -L -o "$TEMP_DMG" "https://ollama.com/download/Ollama.dmg" --progress-bar

        log_info "正在挂载并安装 Ollama..."
        MOUNT_POINT=$(hdiutil attach "$TEMP_DMG" -nobrowse | grep "/Volumes/Ollama" | cut -f 3)
        
        if [ -z "$MOUNT_POINT" ]; then
            log_error "挂载 DMG 失败"
            rm "$TEMP_DMG"
            return 1
        fi

        cp -R "$MOUNT_POINT/Ollama.app" /Applications/
        
        # 清理
        hdiutil detach "$MOUNT_POINT" -quiet
        rm "$TEMP_DMG"
        log_success "Ollama 安装完成！"
    fi

    # 启动 Ollama
    if pgrep -x "Ollama" > /dev/null; then
        log_info "Ollama 正在运行"
    else
        log_info "正在启动 Ollama..."
        open -a /Applications/Ollama.app
        
        # 等待服务就绪
        log_info "等待 Ollama 服务就绪..."
        local retries=0
        while ! curl -s localhost:11434 > /dev/null; do
            sleep 2
            ((retries++))
            if [ $retries -gt 15 ]; then
                log_warn "Ollama 启动较慢，请稍后手动检查状态"
                break
            fi
        done
        log_success "Ollama 服务已就绪"
    fi
}

# 安装 Dria
install_dria() {
    log_info "检查 Dria 环境..."
    
    # 尝试加载环境配置（适配 zsh 和 bash）
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    elif [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi

    if command -v dkn-compute-launcher &> /dev/null; then
        log_success "Dria 已安装"
    else
        log_info "正在下载并安装 Dria..."
        if [ -n "$ARCH_PREFIX" ]; then
            $ARCH_PREFIX bash -c "$(curl -fsSL https://dria.co/launcher)"
        else
            curl -fsSL https://dria.co/launcher | bash
        fi
        
        # 再次尝试加载环境
        if [ -f "$HOME/.zshrc" ]; then
            source "$HOME/.zshrc" 2>/dev/null || true
        elif [ -f "$HOME/.bashrc" ]; then
            source "$HOME/.bashrc" 2>/dev/null || true
        fi
        
        # 如果 source 失败，尝试手动添加到 PATH (假设默认安装路径)
        export PATH="$HOME/.dria/bin:$HOME/.local/bin:$PATH"
        
        if command -v dkn-compute-launcher &> /dev/null; then
             log_success "Dria 安装成功"
        else
             log_error "Dria 安装似乎完成，但在 PATH 中未找到。请重启终端后重试。"
             # 不退出，继续尝试后续步骤（可能会失败）
        fi
    fi
}

# 创建桌面启动脚本
create_launcher() {
    LAUNCHER_PATH="$HOME/Desktop/Start_Dria_Node.command"
    log_info "正在生成桌面启动文件: $LAUNCHER_PATH"
    
    cat > "$LAUNCHER_PATH" <<EOF
#!/bin/bash
DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\${BLUE}========================================\${NC}"
echo -e "\${BLUE}       🚀 Dria 计算节点启动器           \${NC}"
echo -e "\${BLUE}========================================\${NC}"

# 检查架构
ARCH_PREFIX=""
if [[ "\$(uname -m)" == "arm64" ]]; then
    ARCH_PREFIX="arch -x86_64"
    echo -e "\${YELLOW}⚠️  检测到 Apple Silicon，使用 Rosetta 2 模式运行...\${NC}"
fi

# 加载用户环境变量
if [ -f "\$HOME/.zshrc" ]; then source "\$HOME/.zshrc"; fi
if [ -f "\$HOME/.bashrc" ]; then source "\$HOME/.bashrc"; fi
if [ -f "\$HOME/.bash_profile" ]; then source "\$HOME/.bash_profile"; fi

# 确保 Ollama 运行
if ! pgrep -x "Ollama" > /dev/null; then
    echo -e "\${BLUE}启动 Ollama...\${NC}"
    open -a /Applications/Ollama.app
    sleep 5
fi

# 检查 dkn 命令
if ! command -v dkn-compute-launcher &> /dev/null; then
    # 尝试手动添加常见路径
    export PATH="\$HOME/.dria/bin:\$HOME/.local/bin:\$PATH"
fi

if ! command -v dkn-compute-launcher &> /dev/null; then
    echo -e "\${RED}❌ 错误: 未找到 dkn-compute-launcher 命令\${NC}"
    echo "请尝试在终端运行: source ~/.zshrc (或 ~/.bashrc)"
    read -n 1 -s -r -p "按任意键退出..."
    exit 1
fi

echo -e "\${GREEN}正在启动 Dria 节点...\${NC}"
\$ARCH_PREFIX dkn-compute-launcher start

echo -e "\${RED}节点已停止\${NC}"
read -n 1 -s -r -p "按任意键退出..."
EOF

    chmod +x "$LAUNCHER_PATH"
    log_success "桌面启动文件创建完成"
}

# 主流程
main() {
    clear
    echo -e "${BLUE}🚀 开始安装 Dria 计算节点环境...${NC}"
    echo ""

    check_network
    install_ollama
    echo ""
    install_dria
    
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}📝 配置指南${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo "请执行以下步骤获取邀请码（如已有请忽略）："
    echo "1. 新开终端窗口 (Command + N)"
    echo "2. 运行命令: ${GREEN}dkn-compute-launcher referrals${NC}"
    echo "3. 选择 'Get referral code to refer someone'"
    echo ""
    echo "如需修改端口："
    echo "1. 运行命令: ${GREEN}dkn-compute-launcher settings${NC}"
    echo ""
    
    # 交互确认
    if [ -t 0 ]; then
        read -p "✅ 完成上述配置后，请按回车键继续..."
    fi

    create_launcher
    
    echo ""
    log_success "全部安装配置完成！"
    echo -e "🚀 正在尝试首次启动 Dria 节点..."
    
    # 尝试直接启动，如果失败则提示使用桌面图标
    if command -v dkn-compute-launcher &> /dev/null; then
        $ARCH_PREFIX dkn-compute-launcher start
    else
        log_warn "无法在当前 Shell 启动节点，请双击桌面的 [Start_Dria_Node.command] 图标启动。"
    fi
}

# 执行主函数
main
