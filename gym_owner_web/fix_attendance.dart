import 'dart:io';

void main() {
  final file = File('c:/Users/kdev7/Desktop/gym management/gym_management_crm/gym_owner_web/lib/features/attendance/attendance_page.dart');
  String content = file.readAsStringSync();

  // Fix layout wrapper
  content = content.replaceFirst('''                  if (isMobile) {
                    return content;
                  } else {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints.tightFor(
                          width: listWidth,
                          height: constraints.maxHeight,
                        ),
                        child: content,
                      ),
                    );
                  }''', '                  return content;');

  // 1. _AttendanceRow
  content = content.replaceFirst('''    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Container(''', '    return Container(');
      
  content = content.replaceFirst(RegExp(r'''      \);\s*\}\s*return Padding\(\s*padding: const EdgeInsets\.symmetric\(vertical: 8\),\s*child: Row\([\s\S]*?SegmentedButton[\s\S]*?\),\s*\],\s*\),\s*\);\s*\}'''), '''      );
  }''');

  // 2. _StaffAttendanceRow
  content = content.replaceFirst('''    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Container(''', '    return Container(');
      
  content = content.replaceFirst(RegExp(r'''      \);\s*\}\s*return Padding\(\s*padding: const EdgeInsets\.symmetric\(vertical: 8\),\s*child: Row\([\s\S]*?SegmentedButton[\s\S]*?\),\s*\],\s*\),\s*\);\s*\}'''), '''      );
  }''');

  // 3. _TrainerAttendanceRow
  content = content.replaceFirst('''    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Container(''', '    return Container(');
      
  content = content.replaceFirst(RegExp(r'''      \);\s*\}\s*return Padding\(\s*padding: const EdgeInsets\.symmetric\(vertical: 8\),\s*child: Row\([\s\S]*?SegmentedButton[\s\S]*?\),\s*\],\s*\),\s*\);\s*\}'''), '''      );
  }''');

  file.writeAsStringSync(content);
  print('Done!');
}
