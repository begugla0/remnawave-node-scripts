# Remnawave Node Helper Scripts

Быстрые скрипты для установки и удаления Remnawave Node на сервере с Ubuntu 24.04+.

## Установка ноды

```bash
curl -O https://raw.githubusercontent.com/begugla0/remnawave-node-scripts/main/remnanode-install.sh && chmod +x remnanode-install.sh && sudo ./remnanode-install.sh
```

Скрипт:
- Обновит систему и установит Docker + docker compose plugin при необходимости.
- Спросит путь к директории проекта (по умолчанию `/opt/remnanode`).
- Просит вставить **полный** `docker-compose.yml` для Remnawave Node.
- Сохранит файл и предложит запустить `docker compose up -d`.

## Удаление ноды

```bash
curl -O https://raw.githubusercontent.com/begugla0/remnawave-node-scripts/main/remnanode-uninstall.sh && chmod +x remnanode-uninstall.sh && sudo ./remnanode-uninstall.sh
```

Скрипт:
- Спросит путь к директории ноды (по умолчанию `/opt/remnanode`).
- Выполнит `docker compose down -v --rmi all --remove-orphans`.
- По желанию удалит директорию проекта.
