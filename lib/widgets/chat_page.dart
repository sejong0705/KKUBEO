import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../gpt_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages(); // 앱 실행 시 저장된 메시지 불러오기
  }
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('chat_messages');
    if (stored != null) {
      final List decoded = jsonDecode(stored);
      setState(() {
        messages = decoded.map<Map<String, String>>((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_messages', jsonEncode(messages));
  }

  void _askGPT() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      messages.add({'role': 'user', 'content': input});
      _controller.clear();
    });
    await _saveMessages();

    final reply = await sendMessageToGPT(input);

    setState(() {
      messages.add({'role': 'assistant', 'content': reply});
    });
    await _saveMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI 챗봇")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';

                return Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 250),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.deepPurple[300] : Colors
                              .grey[800],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isUser ? 12 : 0),
                            bottomRight: Radius.circular(isUser ? 0 : 12),
                          ),
                        ),
                        child: Text(
                          msg['content'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
            child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 120, // 📏 최대 높이 제한 (예: 5~6줄)
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                reverse: true,
                padding: EdgeInsets.zero,
                  child: TextField(
                    maxLines: null,          // 제한 없이 줄바꿈 가능
                    minLines: 1,             // 기본 1줄
                    keyboardType: TextInputType.multiline,  // 엔터 가능하게
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "메시지를 입력하세요",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
          ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _askGPT,
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}