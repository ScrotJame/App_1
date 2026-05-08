extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  String capitalizeWords() {
    return split(' ')
        .map(
          (e) => e.isEmpty
          ? e
          : "${e[0].toUpperCase()}${e.substring(1)}",
    )
        .join(' ');
  }
}