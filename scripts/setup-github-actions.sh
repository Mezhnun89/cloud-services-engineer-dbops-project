#!/usr/bin/env bash
# Run as user on the training VM. No database migrations are run by this script.
set +x
set -euo pipefail
umask 077

REPO='Mezhnun89/cloud-services-engineer-dbops-project'
VM_HOST='84.201.130.15'
EXPECTED_HOST_FP='SHA256:GpB+rFj97wLPIaM/K5n0pL9AnmgJ2op0n5BietbdVzU'
RUNTIME_DIR="$HOME/dbops-runtime"
CI_KEY="$RUNTIME_DIR/github_actions_ed25519"
HOST_PUBLIC_KEY='/etc/ssh/ssh_host_ed25519_key.pub'

[[ "$(id -un)" == user ]] || { echo 'Запусти скрипт от пользователя user на учебной ВМ.' >&2; exit 1; }
[[ -r "$RUNTIME_DIR/postgres.env" && -r "$HOST_PUBLIC_KEY" ]] || {
  echo 'Не найдены файлы настроенной учебной ВМ.' >&2; exit 1;
}
ACTUAL_HOST_FP="$(ssh-keygen -lf "$HOST_PUBLIC_KEY" -E sha256 | awk '{print $2}')"
[[ "$ACTUAL_HOST_FP" == "$EXPECTED_HOST_FP" ]] || {
  echo 'Отпечаток SSH-сервера отличается от ранее проверенного. Настройка остановлена.' >&2; exit 1;
}
# Existing trusted runtime file, not a file downloaded from GitHub.
source "$RUNTIME_DIR/postgres.env"
: "${STORE_PASSWORD:?В postgres.env отсутствует STORE_PASSWORD}"
# The unchanged upstream test step expands the password without shell quotes.
[[ "$STORE_PASSWORD" =~ ^[[:xdigit:]]{32,}$ ]] || {
  echo 'Формат пароля отличается от созданного для проекта. Нужна проверка настроек.' >&2; exit 1;
}

if ! command -v gh >/dev/null 2>&1; then
  sudo apt-get -o DPkg::Lock::Timeout=300 install -y gh
fi

# Keep this one-time login separate from any existing gh login. This private
# temporary config is removed on exit, including a failed secret upload.
AUTH_DIR="$(mktemp -d "$RUNTIME_DIR/github-auth.XXXXXX")"
chmod 700 "$AUTH_DIR"
cleanup() {
  unset STORE_PASSWORD POSTGRES_PASSWORD
  rm -rf -- "$AUTH_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
export GH_CONFIG_DIR="$AUTH_DIR"
unset GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN
export GH_PAGER=cat
printf '\nВойди в GitHub как Mezhnun89 по коду, который покажет gh.\n'
printf 'Открой https://github.com/login/device в браузере на своём компьютере.\n\n'
gh auth login --hostname github.com --git-protocol https --web --insecure-storage
LOGIN="$(gh api user --jq .login)"
[[ "$LOGIN" == Mezhnun89 ]] || { echo 'Вход выполнен не в аккаунт Mezhnun89.' >&2; exit 1; }
PERMISSION="$(gh repo view "$REPO" --json viewerPermission --jq .viewerPermission)"
[[ "$PERMISSION" == ADMIN ]] || { echo 'Нужны права администратора целевого репозитория.' >&2; exit 1; }

# A dedicated CI key; never upload the user's interactive VM key.
if [[ ! -f "$CI_KEY" ]]; then
  ssh-keygen -q -t ed25519 -N '' -C dbops-github-actions -f "$CI_KEY"
fi
chmod 600 "$CI_KEY"
PUBLIC_KEY="$(ssh-keygen -y -f "$CI_KEY")"
AUTHORIZED_LINE="restrict,port-forwarding,permitopen=\"127.0.0.1:5432\",command=\"/bin/false\" $PUBLIC_KEY dbops-github-actions"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
if ! grep -Fxq -- "$AUTHORIZED_LINE" "$HOME/.ssh/authorized_keys"; then
  printf '\n%s\n' "$AUTHORIZED_LINE" >> "$HOME/.ssh/authorized_keys"
fi
KNOWN_HOST="$(awk -v host="$VM_HOST" '{print host " " $1 " " $2}' "$HOST_PUBLIC_KEY")"

# Values go through stdin to encrypted Actions Secrets, never into public Git.
printf '%s' '127.0.0.1'     | gh secret set DB_HOST --repo "$REPO"
printf '%s' '15432'         | gh secret set DB_PORT --repo "$REPO"
printf '%s' 'store'         | gh secret set DB_NAME --repo "$REPO"
printf '%s' 'store_migrator' | gh secret set DB_USER --repo "$REPO"
printf '%s' "$STORE_PASSWORD" | gh secret set DB_PASSWORD --repo "$REPO"
printf '%s' "$VM_HOST"     | gh secret set SSH_HOST --repo "$REPO"
gh secret set SSH_PRIVATE_KEY --repo "$REPO" < "$CI_KEY"
printf '%s\n' "$KNOWN_HOST" | gh secret set SSH_KNOWN_HOSTS --repo "$REPO"
unset STORE_PASSWORD POSTGRES_PASSWORD

gh workflow run main.yml --repo "$REPO" --ref main -f target=4
printf '\nCI_SETUP_OK: секреты записаны, запуск workflow запрошен.\n'
printf 'Результат тестов смотри здесь: https://github.com/%s/actions\n' "$REPO"
