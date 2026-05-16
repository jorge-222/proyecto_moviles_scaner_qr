import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener la sesión actual
  Session? get currentSession => _supabase.auth.currentSession;

  // Stream para escuchar cambios en la autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Iniciar sesión con Google
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      // Esto es para que en el celular abra el navegador
      redirectTo: 'io.supabase.stylestockqr://login-callback/',
    );
  }

  // Iniciar sesión con GitHub
  Future<void> signInWithGithub() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: 'io.supabase.stylestockqr://login-callback/',
    );
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
