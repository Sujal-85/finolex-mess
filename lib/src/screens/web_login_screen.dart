import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';

class WebLoginScreen extends StatefulWidget {
  final String email;
  final String password;
  final String targetUrl;

  const WebLoginScreen({
    super.key,
    required this.email,
    required this.password,
    this.targetUrl =
        'https://prasanna-caterers.vercel.app/login', // Assumed login route, fallback to root if needed
  });

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  late final WebViewController _controller;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);

              if (!_hasError) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attempting auto-login...'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                _injectLoginScript();
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
            // Check for specific network errors if needed, but for now catch all main load errors
            if (error.errorType == WebResourceErrorType.connect ||
                error.errorType == WebResourceErrorType.hostLookup ||
                error.errorType == WebResourceErrorType.timeout ||
                error.description.contains('net::ERR_INTERNET_DISCONNECTED')) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.targetUrl));
  }

  void _injectLoginScript() async {
    // Aggressive Polling script with multiple strategies
    const script = '''
      (function() {
        var checkCount = 0;
        var maxChecks = 40; // 20 seconds at 500ms
        
        function findElement(selectors) {
            for (var i = 0; i < selectors.length; i++) {
                var el = document.querySelector(selectors[i]);
                if (el) return el;
            }
            return null;
        }

        function findButtonByText() {
            var buttons = document.querySelectorAll('button');
            for (var i = 0; i < buttons.length; i++) {
                var text = buttons[i].innerText.toLowerCase();
                if (text.includes('login') || text.includes('sign in') || text.includes('submit')) {
                    return buttons[i];
                }
            }
            return null;
        }

        var intervalId = setInterval(function() {
            checkCount++;
            
            // Strategy 1: Standard Selectors
            var emailField = findElement([
                'input[type="email"]', 
                'input[name="email"]', 
                'input[name="username"]',
                'input[placeholder*="Email"]',
                'input[placeholder*="Username"]'
            ]);
            
            var passwordField = findElement([
                'input[type="password"]', 
                'input[name="password"]',
                'input[placeholder*="Password"]'
            ]);

            // Strategy 2: Fallback to DOM Order (Riskier but effective for simple login pages)
            if (!emailField) {
                var allInputs = document.querySelectorAll('input[type="text"]');
                if (allInputs.length > 0 && allInputs.length < 3) emailField = allInputs[0];
            }

            // If we found both fields
            if (emailField && passwordField) {
                clearInterval(intervalId);
                
                // Helper to trigger events
                function triggerEvents(element) {
                    element.dispatchEvent(new Event('input', { bubbles: true }));
                    element.dispatchEvent(new Event('change', { bubbles: true }));
                    element.dispatchEvent(new Event('blur', { bubbles: true }));
                }
    
                // React/Angular Native Setter Hack
                var nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
                
                if (nativeInputValueSetter) {
                    nativeInputValueSetter.call(emailField, "EMAIL_PLACEHOLDER");
                    nativeInputValueSetter.call(passwordField, "PASSWORD_PLACEHOLDER");
                } else {
                    emailField.value = "EMAIL_PLACEHOLDER";
                    passwordField.value = "PASSWORD_PLACEHOLDER";
                }
                
                triggerEvents(emailField);
                triggerEvents(passwordField);
    
                // Find Submit Button
                var submitBtn = document.querySelector('button[type="submit"]') || findButtonByText();
    
                if (submitBtn) {
                    setTimeout(() => submitBtn.click(), 500);
                } else {
                   // Fallback: submit form directly
                   var form = emailField.closest('form');
                   if(form) form.submit();
                }
            }
            
            if (checkCount >= maxChecks) {
                clearInterval(intervalId);
            }
        }, 500);
      })();
    ''';

    final validScript = script
        .replaceAll('EMAIL_PLACEHOLDER', widget.email)
        .replaceAll('PASSWORD_PLACEHOLDER', widget.password);

    try {
      await _controller.runJavaScript(validScript);
    } catch (e) {
      debugPrint('Error injecting script: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Portal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            // Logout to prevent auto-login loop and return to login screen
            await AuthService().logout();
            if (context.mounted) context.go('/login');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          _hasError
              ? _buildErrorView()
              : WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Internet Connection',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
              _controller.reload();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
