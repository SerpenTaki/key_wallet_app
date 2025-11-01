#!/bin/bash
# ===============================
# Flutter coverage cleaner script
# ===============================

echo "Pulizia flutter"
flutter clean

echo "Pub Get"
flutter pub get

echo "Eseguo test Flutter con coverage..."
flutter test --coverage

echo "Genero report HTML..."
genhtml coverage/lcov.info -o coverage/html

echo "open coverage/html/index.html"
open coverage/html/index.html


