import '../models/about_model.dart';

class AboutService {
  static final AboutService _instance = AboutService._internal();
  factory AboutService() => _instance;
  AboutService._internal();

  AppInfo getAppInfo() {
    return AppInfo(
      appName: 'FAMT Mess App',
      version: 'v1.0.0',
      buildNumber: '100',
      lastUpdate: 'Nov 30, 2025',
      description:
          'The FAMT Mess App is designed to provide a seamless dining experience for hostel students. Our mission is to simplify meal planning, payments, and communication between students and mess staff.',
    );
  }

  List<Developer> getDevelopers() {
    return [
      Developer(
        name: 'Sujal Sadanand Khedekar',
        role: 'Lead Developer & Creator',
        contact: 'khedekarsujay720@gmail.com',
        imageUrl: 'assets/images/profile_placeholder.png',
      ),
    ];
  }

  List<Contributor> getContributors() {
    return [
      Contributor(
        name: 'Dr. Admin Team',
        role: 'Administrative Support',
        imageUrl: 'assets/images/profile_placeholder.png',
      ),
      Contributor(
        name: 'Mess Staff',
        role: 'Culinary Experts',
        imageUrl: 'assets/images/profile_placeholder.png',
      ),
      Contributor(
        name: 'Management',
        role: 'Operations Oversight',
        imageUrl: 'assets/images/profile_placeholder.png',
      ),
    ];
  }
}
