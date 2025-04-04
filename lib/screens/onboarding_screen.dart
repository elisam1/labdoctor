import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lab_technician_dashboard.dart'; // Removed patient dashboard import

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required String role}); // Removed role parameter

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  // Updated onboarding content specifically for lab technicians
  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: "Welcome to LabConnect Pro",
      description: "Your professional laboratory management system",
      icon: Icons.medical_services,
      color: Color(0xFF4A6FA5), // Blue
    ),
    OnboardingItem(
      title: "Efficient Sample Processing",
      description: "Track and manage lab samples with real-time updates",
      icon: Icons.science,
      color: Color(0xFF6B8E23), // Olive
    ),
    OnboardingItem(
      title: "Advanced Analysis Tools",
      description: "Generate detailed lab reports with integrated analytics",
      icon: Icons.analytics,
      color: Color(0xFFD2691E), // Chocolate
    ),
    OnboardingItem(
      title: "Secure Technician Portal",
      description: "Role-based access with enterprise-grade security",
      icon: Icons.security,
      color: Color(0xFF4682B4), // Steel Blue
    ),
  ];

  // Updated feature items focused on lab technician workflow
  final List<FeatureItem> _featureItems = [
    FeatureItem(icon: Icons.science, title: "Sample Processing"),
    FeatureItem(icon: Icons.assignment, title: "Test Management"),
    FeatureItem(icon: Icons.insert_chart, title: "Results Analysis"),
    FeatureItem(icon: Icons.picture_as_pdf, title: "Report Generation"),
    FeatureItem(icon: Icons.notifications, title: "Critical Alerts"),
    FeatureItem(icon: Icons.print, title: "Print Labels/Reports"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background color transition
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            color: _currentPage < _onboardingItems.length 
                ? _onboardingItems[_currentPage].color.withOpacity(0.1)
                : Colors.grey[100],
          ),
          
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
                _isLastPage = page == _onboardingItems.length;
              });
            },
            children: [
              ..._onboardingItems.map((item) => _buildOnboardingPage(item)),
              _buildFeaturesGrid(),
            ],
          ),
          
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => _completeOnboarding(context),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // Page indicator
          Positioned(
            bottom: _isLastPage ? 120 : 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingItems.length + 1,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index 
                        ? _onboardingItems[_currentPage < _onboardingItems.length 
                            ? _currentPage 
                            : 0].color
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
          
          // Get Started button (only on last page)
          if (_isLastPage)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () => _completeOnboarding(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _onboardingItems[0].color,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Enter Lab Portal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 60,
              color: item.color,
            ),
          ),
          SizedBox(height: 40),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        children: [
          Text(
            "Lab Technician Features",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Professional tools for laboratory management",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _featureItems.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _featureItems[index].icon,
                          size: 30,
                          color: _onboardingItems[index % _onboardingItems.length].color,
                        ),
                        SizedBox(height: 10),
                        Text(
                          _featureItems[index].title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeUser', false);

    // Direct navigation to LabTechnicianDashboard (no role check needed)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LabTechnicianDashboard(),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class FeatureItem {
  final IconData icon;
  final String title;

  FeatureItem({required this.icon, required this.title});
}