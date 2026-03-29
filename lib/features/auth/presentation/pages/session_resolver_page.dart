import 'package:flutter/material.dart';

import '../../../../core/session/session_context.dart';
import '../../../../core/utils/message_helper.dart';
import '../presenters/session_resolver_presenter.dart';

class SessionResolverPage extends StatefulWidget {
  const SessionResolverPage({super.key});

  @override
  State<SessionResolverPage> createState() => _SessionResolverPageState();
}

class _SessionResolverPageState extends State<SessionResolverPage> {
  SessionResolverPresenter? _presenter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolve();
    });
  }

  Future<void> _resolve() async {
    final result = await (_presenter ??= SessionResolverPresenter())
        .resolve(refresh: true);

    if (!mounted) {
      return;
    }

    final target = result.isSuccess ? result.data! : AppRouteTarget.auth;
    if (result.isFailure) {
      MessageHelper.showSnackBar(context, result.error!.message);
    }

    Navigator.pushReplacementNamed(context, target.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
