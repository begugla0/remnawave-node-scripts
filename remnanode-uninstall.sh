#!/usr/bin/env bash

set -e

BOLD=$(tput bold 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
CYAN=$(tput setaf 6 2>/dev/null || echo "")
NC=$(tput sgr0 2>/dev/null || echo "")

echo -e "${BOLD}${CYAN}=== Remnawave Node uninstall (docker-compose project only) ===${NC}\n"

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Рекомендуется запускать от root или через: sudo $0${NC}"
  read -rp "Продолжить без root? [y/N]: " CONT
  CONT=${CONT,,}
  if [[ "$CONT" != "y" && "$CONT" != "yes" ]]; then
    exit 1
  fi
fi

read -rp "Путь к директории ноды (где docker-compose.yml) [по умолчанию /opt/remnanode]: " PROJECT_DIR
PROJECT_DIR=${PROJECT_DIR:-/opt/remnanode}

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo -e "${RED}Директория ${PROJECT_DIR} не существует.${NC}"
  read -rp "Удалить только контейнеры/образы по имени сервиса? [y/N]: " ONLY_DOCKER
  ONLY_DOCKER=${ONLY_DOCKER,,}
  if [[ "$ONLY_DOCKER" != "y" && "$ONLY_DOCKER" != "yes" ]]; then
    exit 1
  fi
else
  cd "$PROJECT_DIR"
fi

if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Команда 'docker' не найдена. Docker не установлен.${NC}"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo -e "${RED}Команда 'docker compose' недоступна.${NC}"
  exit 1
fi

if [[ -f "${PROJECT_DIR}/docker-compose.yml" ]]; then
  echo -e "${CYAN}Найден ${PROJECT_DIR}/docker-compose.yml${NC}"
  echo -e "${CYAN}Останавливаю и удаляю проект docker compose...${NC}"
  docker compose down -v --rmi all --remove-orphans
  echo -e "${GREEN}Проект docker compose удалён.${NC}"

  read -rp "Удалить директорию проекта ${PROJECT_DIR}? [y/N]: " REMOVE_DIR
  REMOVE_DIR=${REMOVE_DIR,,}
  if [[ "$REMOVE_DIR" == "y" || "$REMOVE_DIR" == "yes" ]]; then
    rm -rf "$PROJECT_DIR"
    echo -e "${GREEN}Директория ${PROJECT_DIR} удалена.${NC}"
  else
    echo -e "${CYAN}Директория ${PROJECT_DIR} оставлена на месте.${NC}"
  fi
else
  echo -e "${RED}В директории ${PROJECT_DIR} нет docker-compose.yml.${NC}"
fi

echo
read -rp "Дополнительно убрать контейнеры/образы с именем 'remnawave'/'remnanode'? [y/N]: " EXTRA_CLEAN
EXTRA_CLEAN=${EXTRA_CLEAN,,}

if [[ "$EXTRA_CLEAN" == "y" || "$EXTRA_CLEAN" == "yes" ]]; then
  echo -e "${CYAN}Удаление контейнеров...${NC}"
  docker ps -a --format '{{.ID}} {{.Names}}' \
    | grep -Ei 'remnawave|remnanode' \
    | awk '{print $1}' \
    | xargs -r docker rm -f

  echo -e "${CYAN}Удаление образов...${NC}"
  docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' \
    | grep -Ei 'remnawave|remnanode' \
    | awk '{print $2}' \
    | xargs -r docker rmi -f

  echo -e "${GREEN}Дополнительная чистка выполнена.${NC}"
fi

echo
echo -e "${GREEN}Удаление ноды Remnawave завершено.${NC}"
echo
echo -e "${CYAN}GitHub репозиторий: https://github.com/begugla0/remnawave-node-scripts${NC}"
