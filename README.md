# deployment

Этот репозиторий содержит конфигурационные файлы для развертывания микросервисного приложения с помощью Docker Swarm, Nginx и Docker Secrets.

## Состав

- `docker-compose.yml` — основной файл для описания сервисов, сетей, томов и секретов.
- `nginx.conf` — конфигурация обратного прокси Nginx.
- `initdb/init.sql` — скрипт инициализации базы данных PostgreSQL.

## Архитектура

В состав стека входят:
- **proxy** — Nginx, выполняющий роль обратного прокси для фронтенда.
- **frontend** — клиентское приложение (React/Next.js), взаимодействующее с backend через API.
- **app** — backend-приложение (Spring), работающее с базой данных и файловым хранилищем.
- **db** — PostgreSQL для хранения данных.

## Быстрый старт

1. **Создайте секреты для Docker Swarm:**
   ```sh
   echo -n "myPassword" | docker secret create db_password -
   echo -n "myUser" | docker secret create db_username -
   echo -n "your_jwt_secret" | docker secret create jwt_secret -
   echo -n "3600000" | docker secret create jwt_expiration_ms -
   ```
   > Замените значения на свои реальные данные.

2. **Инициализируйте swarm (если еще не инициализирован):**
   ```sh
   docker swarm init
   ```

3. **Разверните стек:**
   ```sh
   docker stack deploy -c docker-compose.yml deployment
   ```

4. **Проверьте статус сервисов:**
   ```sh
   docker stack services deployment
   ```

5. **Остановить стек:**
   ```sh
   docker stack rm deployment
   ```

## Описание сервисов

- **proxy**: Nginx, выполняет роль обратного прокси:
  - Все запросы к `/api` и его подмаршрутам проксируются на backend (app, порт 8081), с поддержкой CORS и передачей всех заголовков (включая Authorization для JWT).
  - Все остальные запросы проксируются на frontend (порт 3000).
  - Используется кастомный формат логов и ограничения на размер тела запроса.
  - Конфигурация берётся из локального файла `nginx.conf`.
- **frontend**: Фронтенд-приложение (порт 3000), переменная окружения `NEXT_PUBLIC_API_URL` указывает на backend.
- **app**: Backend-приложение (порт 8081), использует переменные окружения и секреты для подключения к базе и работы с JWT.
- **db**: PostgreSQL (порт 5432), инициализируется скриптом из `initdb/`, использует секреты для пароля.

## Секреты

Для безопасного хранения чувствительных данных используются Docker secrets:
- `db_password` — пароль пользователя БД
- `db_username` — имя пользователя БД
- `jwt_secret` — секрет для подписи JWT
- `jwt_expiration_ms` — время жизни JWT (в миллисекундах)

Создайте секреты перед развертыванием стека (см. выше).

