class PrivacySettings {
  bool shareDetailedStatus;
  bool shareLocation;
  bool shareActiveHours;
  bool allowQuietHours;

  PrivacySettings({
    this.shareDetailedStatus = false, // Default to private
    this.shareLocation = false,
    this.shareActiveHours = true, // This is core to the app's purpose
    this.allowQuietHours = true,
  });

  Map<String, dynamic> toJson() => {
        'shareDetailedStatus': shareDetailedStatus,
        'shareLocation': shareLocation,
        'shareActiveHours': shareActiveHours,
        'allowQuietHours': allowQuietHours,
      };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        shareDetailedStatus: json['shareDetailedStatus'] ?? false,
        shareLocation: json['shareLocation'] ?? false,
        shareActiveHours: json['shareActiveHours'] ?? true,
        allowQuietHours: json['allowQuietHours'] ?? true,
      );
}
