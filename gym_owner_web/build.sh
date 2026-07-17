#!/bin/bash
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi
./flutter/bin/flutter config --enable-web
echo "API_URL=$API_URL" > .env
echo "SOCKET_URL=$SOCKET_URL" >> .env
./flutter/bin/flutter pub get
./flutter/bin/flutter build web --release
