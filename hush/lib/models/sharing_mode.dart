enum SharingMode {
  named,      // "Alex needs quiet"
  anonymous,  // "Someone needs quiet" 
  invisible,  // Don't show at all
}

extension SharingModeExtension on SharingMode {
  String get displayName {
    switch (this) {
      case SharingMode.named:
        return 'Show My Name';
      case SharingMode.anonymous:
        return 'Stay Anonymous';
      case SharingMode.invisible:
        return 'Stay Invisible';
    }
  }

  String get description {
    switch (this) {
      case SharingMode.named:
        return 'Others see your name when you need quiet';
      case SharingMode.anonymous:
        return 'Others see "Someone needs quiet"';
      case SharingMode.invisible:
        return 'Your quiet status is completely private';
    }
  }

  String get icon {
    switch (this) {
      case SharingMode.named:
        return '👤';
      case SharingMode.anonymous:
        return '👥';
      case SharingMode.invisible:
        return '👻';
    }
  }
}
