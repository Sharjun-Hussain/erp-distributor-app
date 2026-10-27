// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadBytes(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Inject and click a synthetic DOM anchor to bypass popup blockers
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;

  html.document.body!.children.add(anchor);
  anchor.click();

  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
