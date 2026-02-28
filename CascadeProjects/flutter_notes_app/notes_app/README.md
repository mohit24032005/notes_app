# Notes App

A Flutter notes application with AI-powered summarization using Google Gemini.

## Features

- Create, edit, and manage notes
- AI-powered note summarization using Google Gemini
- Category organization
- Pin important notes
- User authentication

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- A Google Gemini API key

### Setting Up Google Gemini API Key

#### Step 1: Get Your API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy your API key

#### Step 2: Configure the API Key

You have two options to add your API key:

##### Option A: Using .env File (Recommended)

1. Create a `.env` file in the root directory of the project (same level as `pubspec.yaml`)
2. Add your API key to the file:
   ```
   GEMINI_API_KEY=your_actual_api_key_here
   ```
3. The `.env` file is already in `.gitignore`, so your key won't be committed to version control

##### Option B: Using Compile-Time Environment Variables

For development, you can also pass the API key at compile time:

**Windows (PowerShell):**
```powershell
flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

**Windows (CMD):**
```cmd
flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

**macOS/Linux:**
```bash
flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here
```

**For Android Studio/VS Code:**
Add to your launch configuration:
```json
{
  "dart-define": {
    "GEMINI_API_KEY": "your_actual_api_key_here"
  }
}
```

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── note.dart            # Note data model
├── providers/
│   └── notes_provider.dart  # State management
├── screens/
│   ├── home_screen.dart     # Main notes list
│   ├── login_screen.dart    # User login
│   ├── signup_screen.dart   # User registration
│   └── note_edit_screen.dart # Note editor with AI features
└── services/
    ├── database_helper.dart # Local database
    └── gemini_text_analyzer.dart # Gemini AI integration
```

## Using AI Features

Once your API key is configured:

1. Open or create a note
2. Write some content
3. Tap the AI icon (✨) in the app bar
4. The AI will generate a summary of your note

## Troubleshooting

### "Gemini API key is not configured" Error

- Make sure you've created a `.env` file with `GEMINI_API_KEY=your_key`
- Or use compile-time environment variables as shown above
- Verify your API key is correct and active

### API Key Not Working

- Check that your API key is valid at [Google AI Studio](https://makersuite.google.com/app/apikey)
- Ensure you haven't exceeded API rate limits
- Verify the key has proper permissions

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Google Gemini API Documentation](https://ai.google.dev/docs)
- [Google Generative AI Dart Package](https://pub.dev/packages/google_generative_ai)
