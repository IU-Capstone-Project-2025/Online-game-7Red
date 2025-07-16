FROM ubuntu:latest

# Установка необходимых пакетов
RUN apt-get update && apt-get install -y \
    curl git unzip zip nginx ca-certificates && \
    apt-get clean

# Проверка подключения к GitHub перед клонированием
RUN git ls-remote https://github.com/flutter/flutter.git || exit 1

# Клонирование Flutter с минимальной глубиной для уменьшения размера
RUN git clone --single-branch --branch stable --depth 1 https://github.com/flutter/flutter.git /flutter

# Настройка пути для Flutter и Dart SDK
ENV PATH="$PATH:/flutter/bin:/flutter/bin/cache/dart-sdk/bin"

ARG WS_URL
ENV WS_URL $WS_URL

# Активируем Flutter Web
RUN flutter channel stable && \
    flutter upgrade && \
    flutter config --enable-web

# Копируем проект в контейнер
COPY . /app
WORKDIR /app

# Устанавливаем зависимости и собираем приложение
RUN flutter pub get && flutter build web --release --target=lib/main.dart --dart-define=WS_URL=$WS_URL

# Копируем собранные файлы в папку, обслуживаемую Nginx
RUN cp -r build/web/* /var/www/html

COPY nginx.conf /etc/nginx/sites-enabled/default

# Открываем порт 80 для Nginx
EXPOSE 80

# Запуск Nginx
CMD ["nginx", "-g", "daemon off;"]
