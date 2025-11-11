#!/bin/bash

# 启用严格模式：遇到错误立即退出、未定义变量报错、管道中任一命令失败即视为整体失败
set -euo pipefail

echo "🚀 Starting deployment script..."

# 检查 Homebrew 是否已安装并在 PATH 中
if ! command -v brew &> /dev/null; then
    echo "⚠️  Homebrew not in PATH, checking common locations..."
    
    # 如果是 macOS 系统，尝试常见的 Homebrew 安装路径
    if [[ "$OSTYPE" == "darwin"* ]]; then
        for brew_path in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
            if [[ -x "$brew_path" ]]; then
                echo "🔧 Found Homebrew at $brew_path, setting up environment..."
                eval "$($brew_path shellenv)"
                break
            fi
        done
    fi
    
    # 再次检查 Homebrew 是否可用（确认环境变量配置生效）
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found"
        echo "📦 Please install Homebrew first by running:"
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "After installation, make sure to run the commands it suggests to add brew to your PATH."
        echo "Then run this script again."
        exit 1
    fi
fi

echo "✅ Homebrew found"

# 运行 upgrade-all 脚本以安装/更新软件包
echo "📦 Running upgrade-all to install/update packages..."

# 先检查系统 PATH 中是否存在可直接调用的 upgrade-all 命令
if command -v upgrade-all &> /dev/null; then
    upgrade-all
# 如果 PATH 中没有，检查用户配置目录下的可执行脚本
elif [ -x "$HOME/.config/bin/upgrade-all" ]; then
    python3 "$HOME/.config/bin/upgrade-all"
# 若上述位置均未找到，提示错误并退出
else
    echo "❌ upgrade-all script not found"
    echo "   Expected at: $HOME/.config/bin/upgrade-all"
    exit 1
fi

# 确保 zsh 启动时能加载自定义配置（放在 .config/zsh 目录下）
echo "🔗 Setting up zsh configuration..."
# 检查用户主目录下是否存在 .zshrc 文件（zsh 的默认配置文件）
if [ ! -f "$HOME/.zshrc" ]; then
    # 若不存在，则创建 .zshrc 并写入配置引入语句
    echo "source ~/.config/zsh/zshrc" > "$HOME/.zshrc"
    echo "✅ Created ~/.zshrc with config source"
# 若 .zshrc 已存在，但未包含自定义配置的引入语句
elif ! grep -q "source ~/.config/zsh/zshrc" "$HOME/.zshrc"; then
    # 追加引入语句到现有 .zshrc 中
    echo "source ~/.config/zsh/zshrc" >> "$HOME/.zshrc"
    echo "✅ Added config source to ~/.zshrc"
# 若已包含引入语句，则无需操作
else
    echo "✅ Zsh config source already exists in ~/.zshrc"
fi

# 函数：创建符号链接，处理已有文件/链接的兼容问题
# 参数：
#   $1: 目标文件/目录（被链接的原始路径）
#   $2: 链接名称（要创建的符号链接路径）
#   $3: 显示名称（用于日志输出的友好名称）
create_symlink() {
    local target="$1"
    local link_name="$2"
    local display_name="$3"

    echo "🔗 Setting up $display_name symlink..."

    # 情况1：如果链接已存在且是符号链接
    if [ -L "$link_name" ]; then
        local current
        current=$(readlink "$link_name")
        # 若当前链接指向正确的目标，则无需操作
        if [ "$current" = "$target" ]; then
            echo "✅ $display_name symlink already exists and is correct"
            return 0
        fi
        # 若指向错误目标，则删除旧链接（后续会创建新链接）
        echo "⚠️  $link_name points to $current; updating to $target"
        rm "$link_name"
    # 情况2：如果存在同名文件/目录（非符号链接）
    elif [ -e "$link_name" ]; then
        # 生成备份路径（若默认备份已存在，附加时间戳避免覆盖）
        local backup="${link_name}.backup"
        if [ -e "$backup" ]; then
            backup="${backup}.$(date +%Y%m%d%H%M%S)"
        fi
        # 备份现有文件/目录
        echo "⚠️  Backing up existing $link_name to $backup"
        mv "$link_name" "$backup"
    fi

    # 创建符号链接（覆盖上述两种情况处理后的场景）
    ln -s "$target" "$link_name"
    echo "✅ Symlink ensured: $link_name -> $target"
}

# bash ~/.config/agent-tracker/scripts/install_brew_service.sh

# Create configuration symlinks
# create_symlink "$HOME/.config/.tmux.conf" "$HOME/.tmux.conf" "Tmux"
# create_symlink "$HOME/.config/claude" "$HOME/.claude" "Claude"
# create_symlink "$HOME/.config/codex" "$HOME/.codex" "Codex"

echo "🎉 Deployment complete!"