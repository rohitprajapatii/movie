# Stage Movie App

A Flutter OTT App that displays trending movies, allows searching, and favoriting movies. The app includes offline support to view favorite movies when there's no internet connection.

## Features

- Movie grid display with poster, title, rating, and release year
- Movie detail view with backdrop image, overview, and more details
- Favorites feature with persistent storage
- Offline mode support
- Search functionality
- Clean architecture with BLoC pattern
- Dark theme UI

## Setup Instructions

1. **Get your API Key**:

   - Sign up at [TMDB](https://www.themoviedb.org/signup)
   - Go to your account settings > API and request an API key
   - Replace `YOUR_TMDB_API_KEY` in `lib/core/config/app_constants.dart` with your actual API key

2. **Install Dependencies**:

   ```bash
   flutter pub get
   ```

3. **Run Code Generation** (for JSON serialization and Hive adapters):

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

## Architecture

This project follows Clean Architecture principles with three main layers:

- **Presentation**: Contains UI elements (screens and widgets) and BLoC state management
- **Domain**: Contains use cases, repositories interfaces, and business logic
- **Data**: Contains implementations of repositories, data sources, and models

## Libraries Used

- **State Management**: flutter_bloc, equatable
- **HTTP Requests**: dio
- **JSON Serialization**: json_serializable
- **UI & Icons**: flutter_svg, google_fonts, cached_network_image
- **Offline Storage**: hive, hive_flutter
- **Connectivity**: connectivity_plus
- **Routing**: go_router
- **Logging**: logger
- **Testing**: mockito, flutter_test
