import 'dart:io';

void main() {
  File file = File('lib/services/chat_service.dart');
  String content = file.readAsStringSync();

  // 1. Update createGroupChat
  content = content.replaceAll(
    "'lastMessageTime': FieldValue.serverTimestamp(),",
    "'lastMessageTime': FieldValue.serverTimestamp(),\n      'isLocked': false,\n      'unreadCounts': {},\n      'archivedBy': [],\n      'deletedBy': [],"
  );

  // 3. Update createOrGetDirectChat (already caught by above generally? No, type is different, wait, the replacement string is identical if they both have it, but they did differ slightly.)
  // Let's do a more precise replacement using dart string matching

}
