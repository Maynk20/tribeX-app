# TribeX 📱

> Discover plans, meet people, and make every day a little more
> interesting.

TribeX is a Flutter-based social discovery app designed to help people
discover activities, sports, education, skills, and other plans around
them. Users can explore nearby experiences, connect with hosts, chat
with others, and RSVP to plans.

## ✨ Features

-   🔎 Discover plans and activities
-   📍 Explore plans happening nearby
-   🏃 Sports & outdoor activities
-   🎓 Education & skills
-   💬 Chat and messaging
-   👤 User profiles
-   📅 Create and manage plans
-   🙋 RSVP to activities
-   🌐 In-person and virtual plans
-   🔐 Secure authentication
-   ⚡ Smooth and responsive Flutter UI

## 🛠️ Tech Stack

-   **Framework:** Flutter
-   **Language:** Dart
-   **Backend:** Supabase
-   **Authentication:** Supabase Auth
-   **Database:** PostgreSQL via Supabase
-   **Storage:** Supabase Storage

## 📁 Project Structure

``` text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── services/
├── features/
│   ├── auth/
│   ├── explore/
│   ├── create/
│   ├── messages/
│   └── profile/
├── shared/
│   ├── widgets/
│   └── models/
└── main.dart
```

> The exact structure may evolve as the application grows.

## 🚀 Getting Started

### Prerequisites

Make sure you have:

-   Flutter SDK installed
-   Dart SDK
-   Android Studio or VS Code
-   An Android/iOS emulator or physical device
-   A configured Supabase project

Check your Flutter installation:

``` bash
flutter doctor
```

### Installation

Clone the repository:

``` bash
git clone <your-repository-url>
cd <project-directory>
```

Install dependencies:

``` bash
flutter pub get
```

Run the application:

``` bash
flutter run
```

## 🔐 Environment Configuration

Do not commit private credentials or secrets to Git.

Configure the required Supabase values using the project's
environment/configuration approach.

Typical values include:

``` text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Never expose service-role keys or other privileged credentials in the
Flutter client.

## 🎨 Design Philosophy

TribeX aims for a clean, modern, friendly interface with:

-   Clear typography
-   Consistent spacing
-   Simple navigation
-   Accessible controls
-   Smooth interactions
-   Responsive layouts
-   Fast loading experiences
-   Minimal visual clutter

The UI should feel polished without sacrificing performance.

## ⚡ Performance

The application is designed with performance in mind:

-   Efficient widget rebuilds
-   Optimized network requests
-   Appropriate caching
-   Lazy loading where useful
-   Optimized lists and images
-   Minimal unnecessary dependencies
-   Responsive UI rendering

## 🧪 Testing

Run Flutter's test suite with:

``` bash
flutter test
```

Analyze the project with:

``` bash
flutter analyze
```

Build a release version with:

``` bash
flutter build apk --release
```

## 🔒 Security

Security is treated as a core part of the application.

-   Never commit secrets to Git
-   Validate user input
-   Protect authenticated resources
-   Use appropriate Supabase Row Level Security policies
-   Follow least-privilege access
-   Avoid exposing sensitive user information
-   Keep authentication and authorization checks in place

## 📌 Roadmap

-   [ ] Improve discovery and recommendations
-   [ ] Advanced search and filters
-   [ ] Better messaging experience
-   [ ] Push notifications
-   [ ] Improved plan recommendations
-   [ ] Enhanced profile customization
-   [ ] Performance improvements
-   [ ] More social features

## 🤝 Contributing

Contributions, ideas, bug reports, and improvements are welcome.

Before submitting changes:

1.  Run `flutter analyze`
2.  Run `flutter test`
3.  Verify the affected user flows
4.  Keep changes focused and maintainable

## 📄 License

This project is currently private/proprietary unless otherwise specified
by the project owner.

------------------------------------------------------------------------

Made with ❤️ using Flutter.
