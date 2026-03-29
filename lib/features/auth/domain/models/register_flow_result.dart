class RegisterFlowResult {
  const RegisterFlowResult({
    required this.hasSession,
    this.message,
  });

  final bool hasSession;
  final String? message;
}
