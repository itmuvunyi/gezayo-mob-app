import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import '../../../core/services/storage_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final String selectedLanguage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.selectedLanguage = 'English',
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    String? selectedLanguage,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(repo, storage);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final StorageService _storageService;

  AuthNotifier(this._repository, this._storageService)
      : super(const AuthState()) {
    _loadInitialState();
  }

  void _loadInitialState() {
    final user = _repository.getPersistedUser();
    final lang = _storageService.getLanguage();
    state = state.copyWith(user: user, selectedLanguage: lang);
  }

  Future<bool> loginWithEmail(String email, String password,
      {String role = 'customer'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user =
          await _repository.loginWithEmail(email, password, role: role);
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid credentials. Please try again.');
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> signUpWithEmail(
      String email, String password, String name, String role,
      [String phoneNumber = '']) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signUpWithEmail(
          email, password, name, role, phoneNumber);
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      state = state.copyWith(
          isLoading: false, errorMessage: 'Sign up failed. Please try again.');
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> signInWithGoogle({String role = 'customer'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signInWithGoogle(role: role);
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      state = state.copyWith(
          isLoading: false, errorMessage: 'Google sign in failed.');
      return false;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> switchRole(String newRole) async {
    if (state.user != null) {
      final updated = await _repository.switchRole(state.user!, newRole);
      state = state.copyWith(user: updated);
    }
  }

  void setLanguage(String lang) {
    _storageService.setLanguage(lang);
    state = state.copyWith(selectedLanguage: lang);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(clearUser: true);
  }

  Future<void> deleteAccount() async {
    final uid = state.user?.uid;
    if (uid != null && uid.isNotEmpty) {
      await _repository.deleteAccount(uid);
    }
    state = state.copyWith(clearUser: true);
  }
}

