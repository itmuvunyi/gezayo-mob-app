import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/storage_service.dart';


import '../../../core/services/backend_api_service.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final api = ref.watch(backendApiServiceProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  return AuthRepositoryImpl(storage, api, firestore);
});

abstract class AuthRepository {
  Future<UserModel?> loginWithEmail(String email, String password,
      {String role = 'customer'});
  Future<UserModel?> signUpWithEmail(
      String email, String password, String name, String role,
      [String phoneNumber = '']);
  Future<UserModel?> signInWithGoogle({String role = 'customer'});
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> logout();
  Future<void> deleteAccount(String uid);
  Future<UserModel?> switchRole(UserModel currentUser, String newRole);
  UserModel? getPersistedUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final StorageService _storageService;
  final BackendApiService _apiService;
  final FirestoreService _firestoreService;

  AuthRepositoryImpl(
      this._storageService, this._apiService, this._firestoreService);

  @override
  Future<UserModel?> loginWithEmail(String email, String password,
      {String role = 'customer'}) async {
    try {
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final fbUser = credential.user!;
        final existingUser = await _firestoreService.getUser(fbUser.uid);
        final userRole = (existingUser != null && existingUser.role.isNotEmpty)
            ? existingUser.role
            : role;

        final user = UserModel(
          uid: fbUser.uid,
          fullName: existingUser?.fullName ?? fbUser.displayName ?? email.split('@').first,
          email: fbUser.email ?? email,
          phoneNumber: existingUser?.phoneNumber ?? fbUser.phoneNumber ?? '',
          role: userRole,
        );
        await _firestoreService.saveUser(user);
        await _storageService.setUserRole(user.role);
        await _storageService.setAuthenticated(true);
        return user;
      }
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth login error code: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Invalid email address or password.');
        case 'invalid-email':
          throw Exception('The email address format is invalid.');
        case 'user-disabled':
          throw Exception('This user account has been disabled.');
        case 'too-many-requests':
          throw Exception(
              'Too many failed attempts. Please try again in a few minutes.');
        default:
          throw Exception(e.message ?? 'Authentication failed.');
      }
    } catch (_) {
      // Offline fallback
    }

    final response =
        await _apiService.loginWithEmail(email, password, role: role);
    if (response.isSuccess && response.data != null) {
      final user = UserModel.fromMap(response.data!).copyWith(role: role);
      await _firestoreService.saveUser(user);
      await _storageService.setUserRole(user.role);
      await _storageService.setAuthenticated(true);
      return user;
    }
    throw Exception('Sign in failed. Please check your credentials.');
  }

  @override
  Future<UserModel?> signUpWithEmail(
      String email, String password, String name, String role,
      [String phoneNumber = '']) async {
    try {
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final fbUser = credential.user!;
        await fbUser.updateDisplayName(name);
        final user = UserModel(
          uid: fbUser.uid,
          fullName: name,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
        );
        await _firestoreService.saveUser(user);
        await _storageService.setUserRole(role);
        await _storageService.setAuthenticated(true);
        return user;
      }
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth signup error code: ${e.code}');
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
              'An account already exists with this email. Try signing in.');
        case 'invalid-email':
          throw Exception('The email address format is invalid.');
        case 'weak-password':
          throw Exception('The password provided is too weak.');
        default:
          throw Exception(e.message ?? 'Registration failed.');
      }
    } catch (_) {
      // Offline fallback
    }

    final response = await _apiService.signUpWithPhone(email, name, role);
    if (response.isSuccess && response.data != null) {
      final user = UserModel.fromMap(response.data!).copyWith(
        email: email,
        fullName: name,
        role: role,
      );
      await _firestoreService.saveUser(user);
      await _storageService.setUserRole(role);
      await _storageService.setAuthenticated(true);
      return user;
    }
    throw Exception('Sign up failed. Please try again.');
  }

  @override
  Future<UserModel?> signInWithGoogle({String role = 'customer'}) async {
    try {
      if (kIsWeb) {
        final googleProvider = fb.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential =
            await fb.FirebaseAuth.instance.signInWithPopup(googleProvider);
        final fbUser = userCredential.user;
        if (fbUser != null) {
          final existingUser = await _firestoreService.getUser(fbUser.uid);
          final userRole =
              (existingUser != null && existingUser.role.isNotEmpty)
                  ? existingUser.role
                  : role;
          final user = UserModel(
            uid: fbUser.uid,
            fullName: fbUser.displayName ?? 'Google User',
            email: fbUser.email ?? '',
            phoneNumber: existingUser?.phoneNumber ?? fbUser.phoneNumber ?? '',
            role: userRole,
            avatarUrl: fbUser.photoURL ?? '',
          );
          await _firestoreService.saveUser(user);
          await _storageService.setUserRole(user.role);
          await _storageService.setAuthenticated(true);
          return user;
        }
        return null;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential =
            await fb.FirebaseAuth.instance.signInWithCredential(credential);
        final fbUser = userCredential.user;
        if (fbUser != null) {
          final existingUser = await _firestoreService.getUser(fbUser.uid);
          final userRole =
              (existingUser != null && existingUser.role.isNotEmpty)
                  ? existingUser.role
                  : role;
          final user = UserModel(
            uid: fbUser.uid,
            fullName:
                fbUser.displayName ?? googleUser.displayName ?? 'Google User',
            email: fbUser.email ?? googleUser.email,
            phoneNumber: existingUser?.phoneNumber ?? fbUser.phoneNumber ?? '',
            role: userRole,
            avatarUrl: fbUser.photoURL ?? googleUser.photoUrl ?? '',
          );
          await _firestoreService.saveUser(user);
          await _storageService.setUserRole(user.role);
          await _storageService.setAuthenticated(true);
          return user;
        }
      } else {
        throw Exception('Google Sign-In was cancelled.');
      }
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      final msg = e.toString().replaceAll("Exception: ", "");
      if (msg.contains("popup_closed_by_user") || msg.contains("cancelled")) {
        throw Exception('Google Sign-In was cancelled.');
      }
      throw Exception('Google Sign-In error: $msg');
    }
    return null;
  }



  @override
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null && user.email!.isNotEmpty) {
      try {
        final cred = fb.EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);
        return;
      } on fb.FirebaseAuthException catch (e) {
        debugPrint('Change password FirebaseAuth error: ${e.code}');
        switch (e.code) {
          case 'wrong-password':
          case 'invalid-credential':
            throw Exception('The current password provided is incorrect.');
          case 'weak-password':
            throw Exception('The new password is too weak.');
          case 'requires-recent-login':
            throw Exception('Please re-log in before changing your password.');
          default:
            throw Exception(e.message ?? 'Failed to update password.');
        }
      } catch (e) {
        throw Exception('Failed to update password: $e');
      }
    }

    if (currentPassword.isEmpty) {
      throw Exception('Current password cannot be empty.');
    }
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _storageService.setAuthenticated(false);
  }

  @override
  Future<void> deleteAccount(String uid) async {
    await _firestoreService.deleteUserAccount(uid);
    try {
      await fb.FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      debugPrint('FirebaseAuth delete currentUser error: $e');
    }
    await _storageService.setAuthenticated(false);
  }

  @override
  Future<UserModel?> switchRole(UserModel currentUser, String newRole) async {
    final updated = currentUser.copyWith(role: newRole);
    await _firestoreService.saveUser(updated);
    await _storageService.setUserRole(newRole);
    return updated;
  }

  @override
  UserModel? getPersistedUser() {
    final isAuthenticated = _storageService.isAuthenticated();
    if (!isAuthenticated) return null;

    final role = _storageService.getUserRole();
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    return UserModel(
      uid: fbUser?.uid ?? 'usr-persisted-user',
      fullName: fbUser?.displayName ?? (role == 'rider' ? 'Rider' : 'User'),
      email: fbUser?.email ?? '',
      phoneNumber: fbUser?.phoneNumber ?? '',
      role: role,
    );
  }
}
