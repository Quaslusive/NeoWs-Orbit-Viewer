String spaceRefSlug(String name) => name
    .replaceAll(RegExp(r'[()\[\],]'), '')
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), '-');

Uri spaceRefAsteroidUrl({required String name}) =>
    Uri.parse('https://www.spacereference.org/asteroid/${spaceRefSlug(name)}');
