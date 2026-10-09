#!/usr/bin/env bash
# 릴스 편집 도구 설치 스크립트 (macOS)
# 사용법: 터미널에서  bash setup-mac.sh
set -euo pipefail

MODEL_NAME="ggml-large-v3-turbo-q5_0.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${MODEL_NAME}"
MODEL_DIR="$HOME/.cache/whisper"
VENV_DIR="$HOME/.pycapcut"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "이 스크립트는 macOS 전용입니다." >&2
  exit 1
fi

# 1. Homebrew (설치 중 맥 비밀번호를 물어봅니다)
if ! command -v brew >/dev/null 2>&1; then
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$p" ]] && eval "$("$p" shellenv)" && break
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Homebrew 설치 (맥 비밀번호 입력 필요)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW=/opt/homebrew/bin/brew
  else
    BREW=/usr/local/bin/brew
  fi
  eval "$("$BREW" shellenv)"
  # 새 터미널에서도 brew가 잡히도록 등록
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo "eval \"\$($BREW shellenv)\"" >> "$HOME/.zprofile"
  fi
fi

# 2. yt-dlp, ffmpeg, whisper-cpp
echo "==> brew install yt-dlp ffmpeg whisper-cpp"
brew install yt-dlp ffmpeg whisper-cpp

# 3. whisper 모델
mkdir -p "$MODEL_DIR"
if [[ -s "$MODEL_DIR/$MODEL_NAME" ]]; then
  echo "==> 모델이 이미 있습니다: $MODEL_DIR/$MODEL_NAME"
else
  echo "==> whisper 모델 다운로드 (약 550MB)"
  curl -fL --retry 3 -C - -o "$MODEL_DIR/$MODEL_NAME.part" "$MODEL_URL"
  mv "$MODEL_DIR/$MODEL_NAME.part" "$MODEL_DIR/$MODEL_NAME"
fi

# 4. pycapcut 가상환경 (brew의 python3 우선 사용)
PY="$(brew --prefix)/bin/python3"
[[ -x "$PY" ]] || PY="$(command -v python3)"
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  echo "==> 가상환경 생성: $VENV_DIR"
  "$PY" -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/python" -m pip install --upgrade pycapcut

# 5. 버전 확인
echo
echo "==================== 설치된 버전 ===================="
echo "Homebrew : $(brew --version | head -1)"
echo "yt-dlp   : $(yt-dlp --version)"
echo "ffmpeg   : $(ffmpeg -version | head -1)"
echo "whisper  : $(brew list --versions whisper-cpp)"
echo "모델     : $(ls -lh "$MODEL_DIR/$MODEL_NAME" | awk '{print $5, $NF}')"
echo "python   : $("$VENV_DIR/bin/python" --version)"
echo "pycapcut : $("$VENV_DIR/bin/python" -m pip show pycapcut | awk '/^Version/{print $2}')"
echo "====================================================="
echo "설치 끝!"
