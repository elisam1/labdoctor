import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:labdoctor/services/auth_service.dart';
import 'dart:io';

// 1. AuthState Provider - Tracks the authentication state of the user
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. Profile Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
  );
});

class ProfileRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseStorage storage;

  ProfileRepository({
    required this.firestore,
    required this.auth,
    required this.storage,
  });

  // Get profile data stream
  Stream<Map<String, dynamic>> getProfileStream() {
    final user = auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return firestore.collection('technicians').doc(user.uid).snapshots().map(
          (snapshot) => snapshot.data() ?? {},
        );
  }

  // Get profile data once
  Future<Map<String, dynamic>> getProfile() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final doc = await firestore.collection('technicians').doc(user.uid).get();
    return doc.data() ?? {};
  }

  // Update profile with image handling
  Future<void> updateProfile({
    required String name,
    required String email,
    required String phoneNumber,
    File? profileImage,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Upload image if provided
    String? imageUrl;
    if (profileImage != null) {
      final ref = storage.ref().child('profile_images/${user.uid}');
      await ref.putFile(profileImage);
      imageUrl = await ref.getDownloadURL();
    }

    // Update Firestore
    await firestore.collection('technicians').doc(user.uid).set({
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      if (imageUrl != null) 'profileImageUrl': imageUrl,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update auth email if changed
    if (user.email != email) {
      await user.updateEmail(email);
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Remove from storage
    try {
      await storage.ref().child('profile_images/${user.uid}').delete();
    } catch (e) {
      // Image might not exist, continue
    }

    // Remove from Firestore
    await firestore.collection('technicians').doc(user.uid).update({
      'profileImageUrl': FieldValue.delete(),
    });
  }
}

// 3. Profile Provider (Stream)
final profileProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(profileRepositoryProvider).getProfileStream();
});

// 4. Profile Data Provider (Future - for one-time reads)
final profileDataProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

// 5. Lab Results Repository Provider
final labTechnicianRepositoryProvider = Provider<LabTechnicianRepository>((ref) {
  return LabTechnicianRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class LabTechnicianRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  LabTechnicianRepository({
    required this.firestore,
    required this.auth,
  });

  Future<void> uploadResults({
    required String patientId,
    required String haemoglobin,
    required String malaria,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final profile = await firestore
        .collection('technicians')
        .doc(user.uid)
        .get();

    // Determine if result is critical
    final isCritical = _isCriticalResult(haemoglobin, malaria);

    await firestore.collection('lab_results').add({
      'patientId': patientId,
      'haemoglobin': haemoglobin,
      'malaria': malaria,
      'isCritical': isCritical,
      'technicianId': user.uid,
      'technicianName': profile.data()?['name'] ?? 'Unknown',
      'technicianPhone': profile.data()?['phoneNumber'] ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (isCritical) {
      await _createCriticalNotification(patientId);
    }
  }

  bool _isCriticalResult(String haemoglobin, String malaria) {
    try {
      final hbValue = double.tryParse(haemoglobin) ?? 0;
      return hbValue < 7.0 || malaria.toLowerCase() == 'positive';
    } catch (e) {
      return false;
    }
  }

  Future<void> _createCriticalNotification(String patientId) async {
    await firestore.collection('notifications').add({
      'type': 'critical_result',
      'patientId': patientId,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

// 6. Critical Results Provider
final criticalResultsProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(false);
  }

  return FirebaseFirestore.instance
      .collection('lab_results')
      .where('technicianId', isEqualTo: user.uid)
      .where('isCritical', isEqualTo: true)
      .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 1)))
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty);
});

// 7. Notifications Provider
final notificationsProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// 8. AuthService Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

// 9. Recent Activity Provider
final recentActivityProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('lab_results')
      .where('technicianId', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList());
});

// 10. Profile Image Upload Provider
final profileImageUploadProvider = StateProvider<File?>((ref) => null);

// 11. Profile Edit State Provider
final profileEditProvider = StateNotifierProvider<ProfileEditNotifier, AsyncValue<void>>((ref) {
  return ProfileEditNotifier(ref);
});

class ProfileEditNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ProfileEditNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phoneNumber,
    File? profileImage,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}