#!/bin/bash
# Install Flutter and build the web app

# Download Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

# Get dependencies
flutter pub get

# Build the web app
flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# The output will be in build/web
