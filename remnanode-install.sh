#!/usr/bin/env bash

set -e

BOLD=$(tput bold 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
CYAN=$(tput setaf 6 2>/dev/null || echo "")
NC=$(tput sgr0 2>/dev/null || echo "")

echo -e "${BOLD}${CYAN}=== Remnawave Node full setup (Docker + docker-compose) ===${NC}\n"

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Запусти скрипт от root или через: sudo $0${NC}"
  exit 1
fi

echo -e "${CYAN}1) Обновление системы и базовых пакетов...${NC}"
apt update -y
apt upgrade -y

apt install -y ca-certificates curl gnupg lsb-release

if ! command -v docker >/dev/null 2>&1; then
  echo -e "${CYAN}2) Установка Docker Engine из официального репозитория...${NC}"

  install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  chmod a+r /etc/apt/keyrings/docker.gpg

  UBUNTU_CODENAME=$( . /etc/os-release && echo "$VERSION_CODENAME" )

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt update -y

  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable docker
  systemctl start docker

  echo -e "${GREEN}Docker установлен.${NC}"
else
  echo -e "${GREEN}Docker уже установлен, пропускаю установку.${NC}"
fi

echo -e "${CYAN}Проверка версий Docker и docker compose...${NC}"
docker --version || { echo -e "${RED}docker не найден в PATH.${NC}"; exit 1; }
docker compose version || { echo -e "${RED}docker compose plugin не установлен.${NC}"; exit 1; }

echo
read -rp "Путь к директории проекта [по умолчанию /opt/remnanode]: " PROJECT_DIR
PROJECT_DIR=${PROJECT_DIR:-/opt/remnanode}

echo -e "${CYAN}Использую директорию: ${PROJECT_DIR}${NC}"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

COMPOSE_FILE="docker-compose.yml"

if [[ -f "$COMPOSE_FILE" ]]; then
  echo
  echo -e "${BOLD}Файл ${COMPOSE_FILE} уже существует.${NC}"
  read -rp "Перезаписать его? [y/N]: " OVERWRITE
  OVERWRITE=${OVERWRITE,,}
  if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "yes" ]]; then
    echo -e "${GREEN}Оставляю существующий docker-compose.yml без изменений.${NC}"
  else
    NEED_NEW_COMPOSE=1
  fi
else
  NEED_NEW_COMPOSE=1
fi

if [[ "$NEED_NEW_COMPOSE" == "1" ]]; then
  echo
  echo -e "${BOLD}${CYAN}Вставь ПОЛНЫЙ docker-compose.yml целиком (как в документации/панели).${NC}"
  echo -e "${CYAN}Когда закончишь вставку, нажми Enter, затем Ctrl+D на новой строке.${NC}"
  echo

  USER_COMPOSE=$(</dev/stdin)

  if [[ -z "$USER_COMPOSE" ]]; then
    echo -e "${RED}Пустой ввод. Файл ${COMPOSE_FILE} не создан.${NC}"
    exit 1
  fi

  printf '%s\n' "$USER_COMPOSE" > "$COMPOSE_FILE"

  echo
  echo -e "${GREEN}Файл ${COMPOSE_FILE} создан/перезаписан.${NC}"
fi

echo
echo -e "${CYAN}Текущий ${COMPOSE_FILE}:${NC}"
echo "----------------------------------------"
cat "$COMPOSE_FILE"
echo
echo "----------------------------------------"

echo
read -rp "Запустить docker compose up -d сейчас? [y/N]: " RUN_NOW
RUN_NOW=${RUN_NOW,,}

if [[ "$RUN_NOW" == "y" || "$RUN_NOW" == "yes" ]]; then
  echo -e "${CYAN}Запускаю: docker compose up -d${NC}"
  docker compose up -d
  echo -e "${CYAN}Показать логи? [y/N]: ${NC}\c"
  read -r SHOW_LOGS
  SHOW_LOGS=${SHOW_LOGS,,}
  if [[ "$SHOW_LOGS" == "y" || "$SHOW_LOGS" == "yes" ]]; then
    docker compose logs -f -t
  fi
else
  echo -e "${GREEN}Готово. Для запуска выполни:${NC}"
  echo "cd ${PROJECT_DIR} && docker compose up -d && docker compose logs -f -t"
fi

echo
echo -e "${GREEN}Установка Remnawave Node завершена.${NC}"
echo
echo -e "${CYAN}GitHub репозиторий: https://github.com/begugla0/remnawave-node-scripts${NC}"
