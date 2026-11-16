#!/usr/bin/env bash
# 安装 course-ppt-maker 到 Codex 的用户技能目录。可在仓库里运行，也可通过 curl 管道运行。
set -euo pipefail

SKILL_NAME="course-ppt-maker"
INSTALL_DIR="${CODEX_SKILLS_DIR:-$HOME/.agents/skills}"
TARGET_DIR="$INSTALL_DIR/$SKILL_NAME"
REPO_TARBALL_URL="${REPO_TARBALL_URL:-https://github.com/laughing-glitch/course-ppt-maker-skill/archive/refs/heads/main.tar.gz}"

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
SOURCE_DIR="${SCRIPT_DIR:+$SCRIPT_DIR/skills/$SKILL_NAME}"
TMP_DIR=""
cleanup() { [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [ -z "$SOURCE_DIR" ] || [ ! -f "$SOURCE_DIR/SKILL.md" ]; then
  TMP_DIR="$(mktemp -d)"
  echo "正在下载 Skill..."
  curl -fsSL "$REPO_TARBALL_URL" | tar -xz -C "$TMP_DIR"
  SOURCE_DIR="$(find "$TMP_DIR" -type d -path "*/skills/$SKILL_NAME" | head -n 1)"
  if [ -z "$SOURCE_DIR" ]; then
    echo "下载的内容里没有找到 Skill，请检查网络后重试。"
    exit 1
  fi
fi

mkdir -p "$INSTALL_DIR"
if [ -d "$TARGET_DIR" ]; then
  BACKUP_ROOT="$(dirname "$INSTALL_DIR")/skill-backups"
  mkdir -p "$BACKUP_ROOT"
  BACKUP="$BACKUP_ROOT/$SKILL_NAME-$(date +%Y%m%d%H%M%S)"
  mv "$TARGET_DIR" "$BACKUP"
  echo "已把旧版本备份到：$BACKUP"
fi
cp -R "$SOURCE_DIR" "$TARGET_DIR"

echo "安装完成：$TARGET_DIR"
echo
echo "重新打开 Codex，新建对话后这样说："
echo "使用 course-ppt-maker，把这份讲稿做成一套直播课件。"
