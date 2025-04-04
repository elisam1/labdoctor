import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  _PatientRecordsScreenState createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _haemoglobinController = TextEditingController();
  final TextEditingController _malariaController = TextEditingController();

  String _searchQuery = '';
  bool _isLoading = false;
  bool _showPatientForm = false;
  bool _showRecordsForPatient = false;
  String? _selectedPatientId;
  String? _selectedPatientName;

  // Color scheme
  static const Color _primaryColor = Color(0xFF2962FF);
  static const Color _secondaryColor = Color(0xFF00BFA5);
  static const Color _criticalColor = Color(0xFFD32F2F);

  @override
  void dispose() {
    _searchController.dispose();
    _patientNameController.dispose();
    _patientIdController.dispose();
    _haemoglobinController.dispose();
    _malariaController.dispose();
    super.dispose();
  }

  Future<void> _addNewPatient() async {
    if (_patientNameController.text.isEmpty || _patientIdController.text.isEmpty) {
      _showSnackBar('Please fill all fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('patients').doc(_patientIdController.text).set({
        'name': _patientNameController.text,
        'id': _patientIdController.text,
        'createdBy': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Patient added successfully');
      _patientNameController.clear();
      _patientIdController.clear();
      setState(() => _showPatientForm = false);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTestResult() async {
    if (_haemoglobinController.text.isEmpty || _malariaController.text.isEmpty) {
      _showSnackBar('Please fill all test fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final haemoglobin = double.tryParse(_haemoglobinController.text);
      final isCritical = haemoglobin != null && haemoglobin < 8.0;
      
      await _firestore.collection('lab_results').add({
        'patientId': _selectedPatientId,
        'patientName': _selectedPatientName,
        'haemoglobin': _haemoglobinController.text.trim(),
        'malaria': _malariaController.text.trim(),
        'technicianId': _auth.currentUser?.uid,
        'technicianEmail': _auth.currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
        'isCritical': isCritical,
      });

      _haemoglobinController.clear();
      _malariaController.clear();

      _showSnackBar('Test results added successfully!');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAndShareReport(Map<String, dynamic> result) async {
    setState(() => _isLoading = true);

    try {
      final reportContent = '''
      LAB REPORT
      ==========
      
      Patient: ${result['patientName']} (${result['patientId']})
      Date: ${(result['timestamp'] as Timestamp).toDate()}
      
      TEST RESULTS:
      - Haemoglobin: ${result['haemoglobin']} g/dL
      - Malaria Test: ${result['malaria']}
      
      Technician: ${result['technicianEmail']}
      ''';

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/lab_report_${result['patientId']}.txt');
      await file.writeAsString(reportContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Lab Report for ${result['patientName']}',
        text: 'Attached is the lab report',
      );
    } catch (e) {
      _showSnackBar('Failed to share report: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPatientForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Patient',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _patientNameController,
              decoration: const InputDecoration(
                labelText: 'Patient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patientIdController,
              decoration: const InputDecoration(
                labelText: 'Patient ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showPatientForm = false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addNewPatient,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Patient'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTestForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Test for $_selectedPatientName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _haemoglobinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Haemoglobin (g/dL)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _malariaController,
              decoration: const InputDecoration(
                labelText: 'Malaria Test Result',
                border: OutlineInputBorder(),
                hintText: 'Positive/Negative',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _haemoglobinController.clear();
                    _malariaController.clear();
                  },
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addTestResult,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Test'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('patients')
          .where('createdBy', isEqualTo: _auth.currentUser?.uid)
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredPatients = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['name'].toString().toLowerCase().contains(_searchQuery) ||
              data['id'].toString().toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredPatients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty 
                      ? 'No patients found' 
                      : 'No matching patients',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _showPatientForm = true),
                  child: const Text('Add First Patient'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredPatients.length,
          itemBuilder: (context, index) {
            final patient = filteredPatients[index];
            final data = patient.data() as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(data['name']),
                subtitle: Text('ID: ${data['id']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedPatientId = data['id'];
                    _selectedPatientName = data['name'];
                    _showRecordsForPatient = true;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPatientRecordsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showRecordsForPatient = false;
                    _selectedPatientId = null;
                    _selectedPatientName = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                '$_selectedPatientName\'s Tests',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => setState(() {}), // Refresh
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        _buildAddTestForm(),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Previous Tests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('lab_results')
                .where('patientId', isEqualTo: _selectedPatientId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No test records found for this patient'),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final record = snapshot.data!.docs[index];
                  final data = record.data() as Map<String, dynamic>;
                  final isCritical = data['isCritical'] == true;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, y - h:mm a').format(
                                    (data['timestamp'] as Timestamp).toDate()),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (isCritical)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _criticalColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _criticalColor),
                                  ),
                                  child: Text(
                                    'CRITICAL',
                                    style: TextStyle(
                                      color: _criticalColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildTestResultChip(
                                'Hb: ${data['haemoglobin']} g/dL',
                                isCritical ? _criticalColor : _primaryColor,
                              ),
                              const SizedBox(width: 8),
                              _buildTestResultChip(
                                'Malaria: ${data['malaria']}',
                                data['malaria'] == 'Positive' 
                                    ? _criticalColor 
                                    : _secondaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () => _generateAndShareReport(data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteTestResult(record.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestResultChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _deleteTestResult(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test Result'),
        content: const Text('Are you sure you want to delete this test result?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('lab_results').doc(docId).delete();
        _showSnackBar('Test result deleted');
      } catch (e) {
        _showSnackBar('Error deleting test result', isError: true);
      }
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showRecordsForPatient 
            ? '$_selectedPatientName\'s Records' 
            : 'Patient Records'),
        actions: [
          if (!_showRecordsForPatient)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _showPatientForm = true),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_showRecordsForPatient)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search patients',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
          if (_showPatientForm) _buildPatientForm(),
          Expanded(
            child: _showRecordsForPatient
                ? _buildPatientRecordsList()
                : _buildPatientList(),
          ),
        ],
      ),
    );
  }
}