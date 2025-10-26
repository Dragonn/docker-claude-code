#!/usr/bin/env bash
set -euo pipefail

# Claude Code Docker installer
# Installs the claude wrapper script to ~/.local/bin

INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_NAME="claude"
DOCKER_IMAGE="${DOCKER_IMAGE:-peterkuczera/claude-code:latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
  echo -e "${GREEN}==>${NC} $1"
}

warn() {
  echo -e "${YELLOW}Warning:${NC} $1"
}

error() {
  echo -e "${RED}Error:${NC} $1" >&2
  exit 1
}

# Detect shell and config file
detect_shell_config() {
  local shell_name
  shell_name="$(basename "${SHELL}")"

  case "${shell_name}" in
    bash)
      if [[ -f "${HOME}/.bashrc" ]]; then
        echo "${HOME}/.bashrc"
      elif [[ -f "${HOME}/.bash_profile" ]]; then
        echo "${HOME}/.bash_profile"
      else
        echo "${HOME}/.bashrc"
      fi
      ;;
    zsh)
      echo "${HOME}/.zshrc"
      ;;
    *)
      echo "${HOME}/.profile"
      ;;
  esac
}

# Get the wrapper script content
get_wrapper_script() {
  # Skip --pull for local images
  local pull_flag=""
  if [[ "${DOCKER_IMAGE}" == */* ]]; then
    pull_flag="--pull=always"
  fi

  cat << EOF
#!/usr/bin/env bash
set -euo pipefail

host_path="\$(realpath "\$(pwd)")"

# Prevent mounting system directories
case "\${host_path}" in
  /|/bin|/sbin|/usr|/usr/*|/etc|/etc/*|/lib|/lib/*|/lib64|/lib64/*|/sys|/sys/*|/proc|/proc/*|/dev|/dev/*|/boot|/boot/*|/root|/root/*)
    echo "Error: Cannot run from system directory: \${host_path}" >&2
    echo "Run from a user directory like /home, /mnt, or /tmp" >&2
    exit 1
    ;;
esac

exec docker run \\
  ${pull_flag} \\
  --rm \\
  -it \\
  --user "\$(id -u):\$(id -g)" \\
  -v "\${HOME}/.claude:\${HOME}/.claude" \\
  -v "\${HOME}/.claude.json:\${HOME}/.claude.json" \\
  -v "\${HOME}/.claude.json.backup:\${HOME}/.claude.json.backup" \\
  -v "\${host_path}:\${host_path}" \\
  -w "\${host_path}" \\
  -e HOME="\${HOME}" \\
  ${DOCKER_IMAGE} "\$@"
EOF
}

main() {
  info "Installing Claude Code Docker wrapper..."

  # Create install directory if it doesn't exist
  mkdir -p "${INSTALL_DIR}"

  # Write the wrapper script
  script_path="${INSTALL_DIR}/${SCRIPT_NAME}"
  get_wrapper_script > "${script_path}"
  chmod +x "${script_path}"

  info "Installed to ${script_path}"

  # Check if install directory is in PATH
  if [[ ":${PATH}:" == *":${INSTALL_DIR}:"* ]]; then
    info "Installation complete! Run: claude"
    exit 0
  fi

  # PATH modification needed
  config_file="$(detect_shell_config)"

  # Check if already added
  if [[ -f "${config_file}" ]] && grep -q "/.local/bin" "${config_file}"; then
    warn "${INSTALL_DIR} not in current PATH, but appears to be in ${config_file}"
    echo "Reload your shell: source ${config_file}"
    exit 0
  fi

  # Add to PATH
  info "Adding ${INSTALL_DIR} to PATH in ${config_file}"
  echo >> "${config_file}"
  echo '# Added by Claude Code installer' >> "${config_file}"
  echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> "${config_file}"

  echo
  info "Installation complete!"
  echo "Reload your shell: source ${config_file}"
  echo "Then run: claude"
}

main "$@"
