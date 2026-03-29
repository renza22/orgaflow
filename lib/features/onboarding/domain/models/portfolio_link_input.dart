class PortfolioLinkInput {
  const PortfolioLinkInput({
    required this.platformCode,
    required this.url,
    required this.sortOrder,
  });

  final String platformCode;
  final String url;
  final int sortOrder;
}
