import 'package:flutter/material.dart';

enum QuietReason {
  general,   // 🔇 Default volume-off icon
  sleeping,  // 🌙 Moon icon  
  working,   // 💻 Laptop icon
}

extension QuietReasonExtension on QuietReason {
  String get displayName {
    switch (this) {
      case QuietReason.general:
        return 'Need Quiet';
      case QuietReason.sleeping:
        return 'Sleeping';
      case QuietReason.working:
        return 'Working';
    }
  }

  IconData get icon {
    switch (this) {
      case QuietReason.general:
        return Icons.volume_off;
      case QuietReason.sleeping:
        return Icons.bed;
      case QuietReason.working:
        return Icons.work;
    }
  }

  String get description {
    switch (this) {
      case QuietReason.general:
        return 'General quiet time';
      case QuietReason.sleeping:
        return 'Trying to sleep';
      case QuietReason.working:
        return 'Focused work time';
    }
  }
}
