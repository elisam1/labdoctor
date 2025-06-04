import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'package:labdoctor/providers/lab_technician_providers.dart';
import 'start_screen.dart';
import 'edit_profile_screen.dart';
import 'patient_records_screen.dart';

class LabTechnicianDashboard extends ConsumerStatefulWidget {
  const LabTechnicianDashboard({super.key});

  @override
  ConsumerState<LabTechnicianDashboard> createState() => _LabTechnicianDashboardState();
}

class _LabTechnicianDashboardState extends ConsumerState<LabTechnicianDashboard> {
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _haemoglobinController = TextEditingController();
  final TextEditingController _malariaController = TextEditingController();
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Color scheme
  static const Color _primaryColor = Color(0xFF2962FF);
  static const Color _secondaryColor = Color(0xFF00BFA5);
  static const Color _criticalColor = Color(0xFFD32F2F);
  static const Color _backgroundLight = Color(0xFFF5F7FA);

  @override
  void dispose() {
    _patientIdController.dispose();
    _haemoglobinController.dispose();
    _malariaController.dispose();
    super.dispose();
  }

  Future<void> _uploadResults() async {
    if (_patientIdController.text.isEmpty) {
      _showSnackBar('Please enter Patient ID', isError: true);
      return;
    }

    if (_haemoglobinController.text.isEmpty || _malariaController.text.isEmpty) {
      _showSnackBar('Please fill all test results', isError: true);
      return;
    }

    try {
      await ref.read(labTechnicianRepositoryProvider).uploadResults(
        patientId: _patientIdController.text,
        haemoglobin: _haemoglobinController.text,
        malaria: _malariaController.text,
      );

      _patientIdController.clear();
      _haemoglobinController.clear();
      _malariaController.clear();

      _showSnackBar('Results uploaded successfully!');
      ref.invalidate(criticalResultsProvider);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _generateAndShareReport(Map<String, dynamic> result) async {
    try {
      final reportContent = '''
      LABDOCTOR DIAGNOSTIC REPORT
      ===========================
      
      Patient ID: ${result['patientId']}
      Date: ${DateFormat('MMM dd, yyyy').format((result['timestamp'] as Timestamp).toDate())}
      
      TEST RESULTS:
      - Haemoglobin: ${result['haemoglobin']} g/dL
      - Malaria Test: ${result['malaria']}
      
      Technician: ${result['technicianPhone'] ?? 'Unknown'}
      Lab: LabDoctor Diagnostics
      ''';

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/lab_report_${result['patientId']}.txt');
      await file.writeAsString(reportContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Lab Report for Patient ${result['patientId']}',
        text: 'Attached is the lab report for your patient',
      );
    } catch (e) {
      _showSnackBar('Failed to share report: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _criticalColor : _secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildNavigationDrawer(AsyncValue<Map<String, dynamic>> profileAsync) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: _primaryColor),
            child: Consumer(
              builder: (context, ref, child) {
                return profileAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (error, stack) => Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                  data: (profile) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          profile['name']?.substring(0, 1) ?? 'T',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile['name'] ?? 'Lab Technician',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Patient Records'),
            selected: _currentIndex == 1,
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ).then((_) => ref.invalidate(profileProvider));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  NotificationsScreen()),
              ).then((_) => ref.invalidate(notificationsProvider));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  SettingsScreen()),
              );
              
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // Add help screen navigation here
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const StartScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(AsyncValue<Map<String, dynamic>> profileAsync) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
          data: (profile) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.medical_services, color: _primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome to LabDoctor', 
                          style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      Text(profile['name'] ?? 'Lab Technician', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(profile['phoneNumber'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Tests Today',
          value: '24',
          icon: Icons.assignment,
          color: _primaryColor,
        ),
        _buildStatCard(
          title: 'Pending',
          value: '5',
          icon: Icons.pending_actions,
          color: Colors.amber,
        ),
        _buildStatCard(
          title: 'Completed',
          value: '19',
          icon: Icons.check_circle,
          color: _secondaryColor,
        ),
        _buildStatCard(
          title: 'Critical',
          value: '2',
          icon: Icons.warning,
          color: _criticalColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
                Text(title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickUploadCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Upload', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _patientIdController,
              decoration: InputDecoration(
                labelText: 'Patient ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _haemoglobinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Haemoglobin (g/dL)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _malariaController,
              decoration: InputDecoration(
                labelText: 'Malaria Test Result',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Positive/Negative',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _uploadResults,
              child: const Text('UPLOAD RESULTS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lab_results')
          .where('technicianId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No recent activity'));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isCritical = data['isCritical'] == true;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityItem(data, isCritical),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> data, bool isCritical) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: isCritical ? _criticalColor : _primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text('Patient ${data['patientId']}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Hb: ${data['haemoglobin']} g/dL • Malaria: ${data['malaria']}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Text(DateFormat('h:mm a').format((data['timestamp'] as Timestamp).toDate()),
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        onTap: () => _generateAndShareReport(data),
      ),
    );
  }

  Widget _buildCriticalAlertBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _criticalColor,
        boxShadow: [
          BoxShadow(
            color: _criticalColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You have critical results requiring attention',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentIndex = 1),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.white),
              ),
            ),
            child: const Text('VIEW NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview(AsyncValue<Map<String, dynamic>> profileAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildWelcomeCard(profileAsync),
          const SizedBox(height: 20),
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildQuickUploadCard(),
          const SizedBox(height: 20),
          _buildRecentActivityHeader(),
          const SizedBox(height: 12),
          _buildRecentActivityList(),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentIndex = 1),
            child: Text(
              'View All',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final criticalAsync = ref.watch(criticalResultsProvider);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildNavigationDrawer(profileAsync),
      appBar: AppBar(
        title: const Text('LabDoctor Technician', 
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationsScreen()),
                ).then((_) => ref.invalidate(notificationsProvider)),
              ),
              notificationsAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (count) => count > 0 ? Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: _criticalColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$count', 
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ) : const SizedBox(),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundLight, Colors.white],
          ),
        ),
        child: Column(
          children: [
            criticalAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (hasCritical) => hasCritical 
                  ? _buildCriticalAlertBanner() 
                  : const SizedBox(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _currentIndex == 0 
                    ? _buildDashboardOverview(profileAsync) 
                    : const PatientRecordsScreen(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}