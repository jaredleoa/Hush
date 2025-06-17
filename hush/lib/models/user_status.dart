class UserStatus {
  final String name;
  final bool isQuietTime;
  final bool isHome;
  final String? generalActivity;
  final bool shareDetails;

  UserStatus({
    required this.name,
    this.isQuietTime = false,
    this.isHome = true,
    this.generalActivity,
    this.shareDetails = true,
  });
}
