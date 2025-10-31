#!/bin/bash
# ===============================
# Flutter coverage cleaner script
# ===============================

# Interrompi in caso di errore
set -e

echo "🧪 Eseguo test Flutter con coverage..."
flutter test --coverage

echo "🧹 Pulisco la coverage da file non necessari..."
# Rimuove i file di widget, schermate e generati automaticamente
lcov --remove coverage/lcov.info \
  'lib/widgets/*' \
  'lib/screens/*' \
  -o coverage/cleaned_lcov.info


echo "📊 Genero report HTML..."
genhtml coverage/cleaned_lcov.info -o coverage/html

echo "✅ Fatto! Apri il report con:"
echo "open coverage/html/index.html"
open coverage/html/index.html


