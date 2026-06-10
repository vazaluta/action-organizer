import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const WeeklyReportApp());
}

class WeeklyReportApp extends StatelessWidget {
  const WeeklyReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '週報アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const WeeklyReportHome(),
    );
  }
}

class WeeklyReportHome extends StatefulWidget {
  const WeeklyReportHome({super.key});

  @override
  State<WeeklyReportHome> createState() => _WeeklyReportHomeState();
}

class _WeeklyReportHomeState extends State<WeeklyReportHome> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'q1': TextEditingController(),
    'q2': TextEditingController(),
    'q3': TextEditingController(),
    'q4': TextEditingController(),
    'q5': TextEditingController(),
    'q6': TextEditingController(),
    'q7': TextEditingController(),
    'q8': TextEditingController(),
    'q9': TextEditingController(),
    'q10': TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('週報'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('1. 今週の振り返り'),
            _questionField('Q1. 今週あなたは何をやろうとしていた？', _controllers['q1']!),
            _questionField('Q2. 今週あなたが実行したことで「特筆すべきこと」は何？', _controllers['q2']!),
            _questionField('Q3. 今週あなたの「資産」は増えた？', _controllers['q3']!),
            const SizedBox(height: 16),
            _sectionHeader('2. 目的の見直し'),
            _questionField('Q4. 今から10年後に必ず願いが叶うとしたらあなたは何を叶える？', _controllers['q4']!),
            _questionField('Q5. その願いを実現する際に直面する課題は何？', _controllers['q5']!),
            _questionField('Q6. その課題を解決した人、参考になる人、質問すべき人は誰？', _controllers['q6']!),
            const SizedBox(height: 16),
            _sectionHeader('3. 来週の目標設定'),
            _questionField('Q7. 1週間後にあなたは死ぬ。今から何をやめるべき？', _controllers['q7']!),
            _questionField('Q8. これからの1週間であなたは何をやるべき？', _controllers['q8']!),
            _questionField('Q9. そのやるべきことの実行で直面する課題は何？', _controllers['q9']!),
            _questionField('Q10. 目の前で「自分」が悩んでいたら何をアドバイスする？', _controllers['q10']!),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('週報を保存する'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy),
              label: const Text('テキストをコピーする'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _questionField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('週報を保存しました！')),
    );
  }

  void _copyToClipboard() {
    final text = '''
# 週報

## 1. 今週の振り返り

Q1. 今週あなたは何をやろうとしていた？
${_controllers['q1']!.text}

Q2. 今週あなたが実行したことで「特筆すべきこと」は何？
${_controllers['q2']!.text}

Q3. 今週あなたの「資産」は増えた？
${_controllers['q3']!.text}

## 2. 目的の見直し

Q4. 今から10年後に必ず願いが叶うとしたらあなたは何を叶える？
${_controllers['q4']!.text}

Q5. その願いを実現する際に直面する課題は何？
${_controllers['q5']!.text}

Q6. その課題を解決した人、参考になる人、質問すべき人は誰？
${_controllers['q6']!.text}

## 3. 来週の目標設定

Q7. 1週間後にあなたは死ぬ。今から何をやめるべき？
${_controllers['q7']!.text}

Q8. これからの1週間であなたは何をやるべき？
${_controllers['q8']!.text}

Q9. そのやるべきことの実行で直面する課題は何？
${_controllers['q9']!.text}

Q10. 目の前で「自分」が悩んでいたら何をアドバイスする？
${_controllers['q10']!.text}
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('クリップボードにコピーしました！')),
    );
  }
}
