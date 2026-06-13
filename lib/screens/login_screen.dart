import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../services/enrollment_service.dart';
import '../models/teacher.dart';
import 'enrollment_form_screen.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<Teacher> _filteredTeachers = [];
  bool _isSearching = false;
  bool _showResults = false;
  bool _hasInternet = true;
  bool _isRefreshing = false;
  bool _initialLoadComplete = false;
  bool _isAutoRefreshing = false;
  Timer? _autoRefreshTimer;
  int _refreshAttempts = 0;
  static const int maxRefreshAttempts = 3;
  Timer? _connectivityTimer;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Initialize data
    _initializeData();

    // Start connectivity monitoring
    _startConnectivityMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _autoRefreshTimer?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check connectivity and data
      _checkConnectivityAndRefresh();
    }
  }

  Future<void> _checkConnectivityAndRefresh() async {
    final authService = context.read<AuthService>();

    // Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    setState(() {
      _hasInternet = hasInternet;
    });

    // If we have internet but no data, try to fetch
    if (hasInternet && authService.teachers.isEmpty) {
      _performAutoRefresh();
    }
    // If we have internet but were offline, try to refresh
    else if (hasInternet && !_hasInternet) {
      _refreshData();
    }
  }

  void _startConnectivityMonitoring() {
    // Check connectivity every 30 seconds
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnectivityAndRefresh();
    });
  }

  Future<void> _initializeData() async {
    await _checkInternetAndLoadData();
    setState(() {
      _initialLoadComplete = true;
    });

    // Check if auto-refresh is needed after initial load
    _checkAndStartAutoRefresh();
  }

  void _checkAndStartAutoRefresh() {
    final authService = context.read<AuthService>();

    // Cancel any existing timer
    _autoRefreshTimer?.cancel();

    // Check if we need auto-refresh (no data) - regardless of internet status
    if (authService.teachers.isEmpty && _refreshAttempts < maxRefreshAttempts) {
      print(
          'Starting auto-refresh timer (Attempt ${_refreshAttempts + 1}/$maxRefreshAttempts)');

      _autoRefreshTimer = Timer(const Duration(seconds: 5), () {
        _performAutoRefresh();
      });
    }
  }

  Future<void> _performAutoRefresh() async {
    if (_isAutoRefreshing || _refreshAttempts >= maxRefreshAttempts) return;

    setState(() {
      _isAutoRefreshing = true;
    });

    print('Auto-refreshing data... (Attempt ${_refreshAttempts + 1})');

    // Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    setState(() {
      _hasInternet = hasInternet;
    });

    final authService = context.read<AuthService>();

    if (hasInternet) {
      // Try to fetch from API
      await authService.fetchTeachers();

      if (mounted && authService.teachers.isNotEmpty) {
        // Success! Show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.cloud_done_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Data loaded successfully')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        _refreshAttempts = 0; // Reset attempts on success
      } else {
        // Increment attempts on failure
        _refreshAttempts++;
      }
    } else {
      // No internet, try to load from cache
      await authService.loadCachedTeachers();

      if (mounted && authService.teachers.isNotEmpty) {
        // Success! Show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.storage_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Loaded from cache')),
              ],
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        _refreshAttempts = 0; // Reset attempts on success
      } else {
        // Increment attempts on failure
        _refreshAttempts++;
      }
    }

    setState(() {
      _isAutoRefreshing = false;
    });

    // Check if we need another auto-refresh
    if (authService.teachers.isEmpty && _refreshAttempts < maxRefreshAttempts) {
      _checkAndStartAutoRefresh();
    } else if (_refreshAttempts >= maxRefreshAttempts && mounted) {
      // Show final message after max attempts
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unable to load data. Please check your connection and try again.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _checkInternetAndLoadData() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = connectivityResult != ConnectivityResult.none;
    });

    final authService = context.read<AuthService>();

    if (_hasInternet) {
      // Try to fetch from API, but also ensure we have cached data as fallback
      await authService.fetchTeachers();
    } else {
      // Load from cache when offline
      await authService.loadCachedTeachers();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
      _refreshAttempts = 0; // Reset auto-refresh attempts on manual refresh
    });

    // Cancel any auto-refresh timer
    _autoRefreshTimer?.cancel();

    // Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    setState(() {
      _hasInternet = hasInternet;
    });

    final authService = context.read<AuthService>();

    if (hasInternet) {
      // Clear search
      _searchController.clear();
      setState(() {
        _filteredTeachers = [];
        _isSearching = false;
        _showResults = false;
      });

      // Fetch fresh data from API
      await authService.fetchTeachers();

      // Show success message
      if (mounted && authService.teachers.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.refresh_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Data refreshed successfully')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // When offline, just reload from cache
      await authService.loadCachedTeachers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Offline mode - using cached data')),
              ],
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() {
      _isRefreshing = false;
    });

    // Check if auto-refresh is still needed
    if (authService.teachers.isEmpty) {
      _checkAndStartAutoRefresh();
    }
  }

  void _searchTeachers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTeachers = [];
        _isSearching = false;
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    final authService = context.read<AuthService>();
    final results = authService.searchTeachers(query);

    setState(() {
      _filteredTeachers = results;
    });
  }

  void _selectTeacher(Teacher teacher) async {
    // Unfocus search field
    _searchFocusNode.unfocus();

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _LoadingOverlay(
        message: 'Logging in...',
      ),
    );

    // Simulate API delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final authService = context.read<AuthService>();
    final enrollmentService = context.read<EnrollmentService>();

    // Login teacher in AuthService
    authService.loginTeacher(teacher);

    // IMPORTANT FIX: Use setCurrentTeacher instead of setCurrentTeacherId
    // This ensures the full teacher object with barangayId is stored
    enrollmentService.setCurrentTeacher(teacher);

    // Close loading dialog
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Welcome, ${teacher.firstName} ${teacher.lastName}!'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to enrollment form
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EnrollmentFormScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _goBackToSplash() {
    // Cancel auto-refresh when leaving
    _autoRefreshTimer?.cancel();
    _connectivityTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _retryConnection() {
    // Reset attempts and try again
    setState(() {
      _refreshAttempts = 0;
    });
    _checkInternetAndLoadData();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // Show loading indicator while initializing
    if (!_initialLoadComplete) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE0F2FE),
                Color(0xFFBAE6FD),
                Color(0xFF7DD3FC),
                Color(0xFF38BDF8),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0EA5E9),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _hasInternet
                      ? 'Loading teachers...'
                      : 'Loading cached data...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0C4A6E),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2FE),
              Color(0xFFBAE6FD),
              Color(0xFF7DD3FC),
              Color(0xFF38BDF8),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            _buildBackgroundElements(),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back button and status with refresh button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Color(0xFF0C4A6E),
                                ),
                                onPressed: _goBackToSplash,
                                tooltip: 'Back to Home',
                              ),
                            ),
                            Row(
                              children: [
                                // Refresh button
                                if (!_isRefreshing && !_isAutoRefreshing)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        color: _hasInternet
                                            ? const Color(0xFF0EA5E9)
                                            : const Color(0xFFF59E0B),
                                        size: 20,
                                      ),
                                      onPressed: _refreshData,
                                      tooltip: 'Refresh Data',
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                // Auto-refresh indicator
                                if (_isAutoRefreshing)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0EA5E9)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              Color(0xFF0EA5E9),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Auto',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0EA5E9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Online/Offline indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (_hasInternet
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B))
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: (_hasInternet
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B))
                                          .withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _hasInternet
                                            ? Icons.wifi_rounded
                                            : Icons.wifi_off_rounded,
                                        size: 16,
                                        color: _hasInternet
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _hasInternet ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _hasInternet
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Logo and Title
                        _buildHeader(),

                        const SizedBox(height: 40),

                        // Login Card with offline support
                        _buildLoginCard(authService),

                        const SizedBox(height: 24),

                        // Help Section
                        _buildHelpSection(),

                        const SizedBox(height: 20),

                        // Show cache info if offline
                        if (!_hasInternet && authService.teachers.isNotEmpty)
                          _buildOfflineInfo(),

                        // Show auto-refresh info if no data
                        if (authService.teachers.isEmpty &&
                            _refreshAttempts < maxRefreshAttempts &&
                            !_isAutoRefreshing)
                          _buildAutoRefreshInfo(),

                        // Show retry message after max attempts
                        if (authService.teachers.isEmpty &&
                            _refreshAttempts >= maxRefreshAttempts)
                          _buildMaxRetriesReached(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay for refresh
            if (_isRefreshing || _isAutoRefreshing)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0EA5E9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isAutoRefreshing
                              ? 'Auto-refreshing...'
                              : (_hasInternet
                                  ? 'Refreshing...'
                                  : 'Loading cache...'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0C4A6E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoRefreshInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.autorenew_rounded,
            size: 20,
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-retry in progress',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Attempt ${_refreshAttempts + 1} of $maxRefreshAttempts',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF0EA5E9).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaxRetriesReached() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load data',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Please check your connection and tap refresh',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFFEF4444).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Showing cached data from ${_getLastSyncDate()}',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFF59E0B).withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLastSyncDate() {
    // You could store and retrieve last sync date from SharedPreferences
    // For now, return a generic message
    return 'previous session';
  }

  Widget _buildBackgroundElements() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPainter(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo Image Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo Image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ALTERNATIVE LEARNING SYSTEM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0C4A6E),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Login Title
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0C4A6E),
                Color(0xFF0369A1),
              ],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Text(
            'TEACHER LOGIN',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _hasInternet
              ? 'Select your account to continue'
              : 'Offline Mode - Select from cached accounts',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0C4A6E).withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthService authService) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Title
                const Text(
                  'Find Your Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0C4A6E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _hasInternet
                      ? 'Search for your name to continue'
                      : 'Search from cached teacher list',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF0C4A6E).withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    enabled: authService.teachers.isNotEmpty,
                    decoration: InputDecoration(
                      labelText: authService.teachers.isNotEmpty
                          ? 'Search Teacher'
                          : 'No teachers available',
                      hintText: authService.teachers.isNotEmpty
                          ? 'Enter first or last name'
                          : _hasInternet
                              ? 'Loading...'
                              : 'No cached data',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0EA5E9),
                              Color(0xFF0284C7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          authService.teachers.isNotEmpty
                              ? Icons.search_rounded
                              : Icons.search_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _searchTeachers('');
                              },
                              color: Colors.grey,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF0EA5E9),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    onChanged: authService.teachers.isNotEmpty
                        ? _searchTeachers
                        : null,
                  ),
                ),

                const SizedBox(height: 24),

                // Loading Indicator
                if (authService.isLoading)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0EA5E9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasInternet
                              ? 'Loading teachers...'
                              : 'Loading cache...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error Message
                if (authService.errorMessage != null && !authService.isLoading)
                  _buildErrorCard(authService.errorMessage!),

                // No Teachers Available
                if (!authService.isLoading &&
                    authService.teachers.isEmpty &&
                    authService.errorMessage == null)
                  _buildNoTeachersCard(),

                // Search Results
                if (_showResults &&
                    !authService.isLoading &&
                    authService.teachers.isNotEmpty)
                  _buildSearchResults(),

                // Helper Text
                if (!_isSearching &&
                    _filteredTeachers.isEmpty &&
                    !authService.isLoading &&
                    authService.teachers.isNotEmpty)
                  _buildHelperText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTeachersCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _hasInternet ? Icons.cloud_off_rounded : Icons.storage_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _hasInternet ? 'No teachers found' : 'No cached data available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasInternet
                ? 'Please check your connection or try again later'
                : 'Connect to internet to download teacher data',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_hasInternet)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: _retryConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('RETRY CONNECTION'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.1),
            const Color(0xFFDC2626).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredTeachers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No teachers found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different name',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: _filteredTeachers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final teacher = _filteredTeachers[index];
          return _buildTeacherCard(teacher);
        },
      ),
    );
  }

  Widget _buildTeacherCard(Teacher teacher) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectTeacher(teacher),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0EA5E9),
                        Color(0xFF0284C7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      teacher.firstName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Teacher Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${teacher.firstName} ${teacher.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF0C4A6E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              teacher.barangayName ?? 'No barangay assigned',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelperText() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0EA5E9).withOpacity(0.1),
                  const Color(0xFF0284C7).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 48,
              color: const Color(0xFF0EA5E9).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start typing to find your account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.5),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0EA5E9),
                  Color(0xFF0284C7),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Can\'t find your account?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF0C4A6E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasInternet
                ? 'Please contact the ALS administrator to register as a teacher.'
                : 'Connect to internet to sync with server, or use cached data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF0C4A6E).withOpacity(0.7),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Loading Overlay Widget
class _LoadingOverlay extends StatelessWidget {
  final String message;

  const _LoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF0EA5E9),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C4A6E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Background Painter
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw floating circles
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15),
      60,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.25),
      40,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.7),
      50,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.8),
      35,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}