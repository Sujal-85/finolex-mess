class Developer {
  final String name;
  final String role;
  final String contact;
  final String imageUrl;

  Developer({
    required this.name,
    required this.role,
    required this.contact,
    required this.imageUrl,
  });
}

class Contributor {
  final String name;
  final String role;
  final String imageUrl;

  Contributor({required this.name, required this.role, required this.imageUrl});
}

class AppInfo {
  final String appName;
  final String version;
  final String buildNumber;
  final String lastUpdate;
  final String description;

  AppInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.lastUpdate,
    required this.description,
  });
}
