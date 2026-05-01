class AuthService {
  // We simulate a 2-second network delay to mimic connecting to your friend's backend
  Future<String?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    // Mock backend logic: Let's pretend any email with "@test.com" works
    if (email.contains('@test.com') && password.length >= 6) {
      // Returning a dummy JWT token[cite: 1]
      return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_payload"; 
    } else {
      throw Exception('Invalid email or password');
    }
  }

  Future<String?> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    // Mock backend logic: Allow any email with @test.com
    if (email.contains('@test.com') && password.length >= 6) {
      return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_registration_payload"; 
    } else {
      throw Exception('Registration failed. Use a @test.com email and 6+ char password.');
    }
  }

  Future<void> logout() async {
    // In the future, this might alert the backend. 
    // For now, it just simulates a quick delay.
    await Future.delayed(const Duration(milliseconds: 500));
  }
}