import 'sharing_mode.dart';

class PrivacySettings {
  bool shareDetailedStatus;
  bool shareLocation;
  bool shareActiveHours;
  bool allowQuietHours;
  SharingMode sharingMode;
  
  PrivacySettings({
    this.shareDetailedStatus = false, // Default to private
    this.shareLocation = false,
    this.shareActiveHours = true, // This is core to the app's purpose
    this.allowQuietHours = true,
    this.sharingMode = SharingMode.named,
  });
  
  Map<String, dynamic> toJson() => {
    'shareDetailedStatus': shareDetailedStatus,
    'shareLocation': shareLocation,
    'shareActiveHours': shareActiveHours,
    'allowQuietHours': allowQuietHours,
    'sharingMode': sharingMode.index,
  };
  
  factory PrivacySettings.fromJson(Map<String, dynamic> json) => PrivacySettings(
    shareDetailedStatus: json['shareDetailedStatus'] ?? false,
    shareLocation: json['shareLocation'] ?? false,
    shareActiveHours: json['shareActiveHours'] ?? true,
    allowQuietHours: json['allowQuietHours'] ?? true,
    sharingMode: SharingMode.values[json['sharingMode'] ?? 0],
  );
}
