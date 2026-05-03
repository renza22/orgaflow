import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/navigation/app_route_observer.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/auth/presentation/pages/session_resolver_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/organization/presentation/pages/organization_choice_page.dart';
import 'features/organization/presentation/pages/organization_settings_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart'
    as onboarding;
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/members/presentation/pages/members_page.dart';
import 'features/projects/presentation/pages/projects_page.dart';
import 'features/fairness/presentation/pages/fairness_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bubhfsnvulfdmtbocgjq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1Ymhmc252dWxmZG10Ym9jZ2pxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4ODEwNDEsImV4cCI6MjA4ODQ1NzA0MX0.Za-V68_qJo9QxVgTyeWJADR8CZQOq__7XwEux90xMa8',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrgaFlow',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [appRouteObserver],
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SessionResolverPage(),
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/auth':
            page = const AuthPage();
            break;
          case '/forgot-password':
            page = const ForgotPasswordPage();
            break;
          case '/reset-password':
            page = const ResetPasswordPage();
            break;
          case '/organization':
            page = const OrganizationChoicePage();
            break;
          case '/onboarding':
            page = const onboarding.OnboardingPage();
            break;
          case '/dashboard':
            page = const DashboardPage();
            break;
          case '/profile':
            page = const ProfilePage();
            break;
          case '/members':
            page = const MembersPage();
            break;
          case '/projects':
            page = const ProjectsPage();
            break;
          case '/fairness':
            page = const FairnessDashboardPage();
            break;
          case '/organization-settings':
            page = const OrganizationSettingsPage();
            break;
          default:
            page = const SessionResolverPage();
        }
        
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      },
    );
  }
}
