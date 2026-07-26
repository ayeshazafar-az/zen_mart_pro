import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  int count = 0;
  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content
      .replaceAll('Total: \\\$ ', 'Total: Rs. ')
      .replaceAll('Total: \\\$', 'Total: Rs. ')
      .replaceAll('Amount: \\\$ ', 'Amount: Rs. ')
      .replaceAll('Price: \\\$ ', 'Price: Rs. ')
      .replaceAll('Payout: \\\$ ', 'Payout: Rs. ')
      .replaceAll('Earned: \\\$ ', 'Earned: Rs. ')
      .replaceAll('\\\$ \${', 'Rs. \${')
      .replaceAll('\\\$ \$', 'Rs. \$');
    if (content != newContent) {
      file.writeAsStringSync(newContent);
     count++;
     print('Updated \${file.path}');
    }
  }
  print('Updated \$count files.');
}
