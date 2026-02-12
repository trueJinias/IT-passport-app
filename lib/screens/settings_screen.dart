import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _newCardsPerDay = 20;
  final _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final val = await _settingsService.getNewCardsPerDay();
    setState(() {
      _newCardsPerDay = val;
    });
  }

  Future<void> _saveSettings(int value) async {
    setState(() {
      _newCardsPerDay = value;
    });
    await _settingsService.setNewCardsPerDay(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '学習設定',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('1日の新規カード上限'),
            subtitle: Text('$_newCardsPerDay 枚'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // Show dialog to edit
              showDialog(
                  context: context,
                  builder: (context) {
                    int tempValue = _newCardsPerDay;
                    return AlertDialog(
                      title: const Text('1日の新規カード上限'),
                      content: StatefulBuilder(
                        builder: (context, setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$tempValue 枚'),
                              Slider(
                                value: tempValue.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 20,
                                label: tempValue.toString(),
                                onChanged: (val) {
                                  setState(() {
                                    tempValue = val.round();
                                  });
                                },
                              ),
                            ],
                          );
                        }
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                             _saveSettings(tempValue);
                             Navigator.pop(context);
                          },
                          child: const Text('保存'),
                        ),
                      ],
                    );
                  }
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('データの初期化'),
            subtitle: const Text('学習履歴をすべて消去します'),
            trailing: const Icon(Icons.delete, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('警告'),
                  content: const Text('本当に学習履歴を消去しますか？この操作は取り消せません。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () async {
                         // Reset logic here if accessible or via service
                         // For now just close
                         Navigator.pop(context);
                      },
                      child: const Text('消去', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
