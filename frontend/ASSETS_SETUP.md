# Asset Setup Instructions

## Required Images

To complete the homepage implementation, you need to add the following pixel art images to the `assets/images/` directory:

### 1. Cat Avatar (Profile Picture)
- **Filename**: `cat_avatar.png`
- **Location**: `frontend/assets/images/cat_avatar.png`
- **Description**: A pixel art cat avatar for the user profile (circular display)
- **Recommended Size**: 120x120 pixels or larger

### 2. Cat Mascot (Chat Card)
- **Filename**: `cat_mascot.png`
- **Location**: `frontend/assets/images/cat_mascot.png`
- **Description**: A pixel art calico cat mascot (white, orange/tan, and black colors)
- **Recommended Size**: 240x240 pixels or larger

## Update pubspec.yaml

Make sure your `frontend/pubspec.yaml` file includes these assets:

```yaml
flutter:
  assets:
    - assets/images/cat_avatar.png
    - assets/images/cat_mascot.png
```

Or use the directory approach to include all images:

```yaml
flutter:
  assets:
    - assets/images/
```

## Fallback

The code includes emoji fallbacks (🐱) if the images are not found, so the app will still run without the images, but adding the actual pixel art will match the design perfectly.
