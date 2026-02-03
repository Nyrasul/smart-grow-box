import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/grow_box_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // Локальная история чата

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GrowBoxProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(FontAwesomeIcons.robot, color: Color(0xFF00E676), size: 20),
            SizedBox(width: 10),
            Text("ИИ Агроном (Gemini)"),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. СПИСОК СООБЩЕНИЙ
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['role'] == 'user';
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFF00E676).withOpacity(0.2),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe
                            ? const Radius.circular(12)
                            : Radius.zero,
                        bottomRight: isMe
                            ? Radius.zero
                            : const Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. ИНДИКАТОР ЗАГРУЗКИ (Если ИИ думает)
          if (provider.isChatLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Агроном печатает...",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // 3. ПОЛЕ ВВОДА
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Спроси о растении...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text, context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text, BuildContext context) async {
    // 1. Добавляем сообщение пользователя на экран мгновенно
    setState(() {
      _messages.add({'role': 'user', 'text': text});
    });
    _controller.clear();

    // 2. Показываем, что бот думает (через Provider)
    // Можно добавить локальный индикатор, если хочешь

    // 3. Отправляем запрос в "Мозг"
    final provider = context.read<GrowBoxProvider>();
    final responseText = await provider.chatWithGemini(text);

    // 4. Добавляем ответ бота на экран
    if (mounted) {
      // Проверка, что экран не закрыт
      setState(() {
        _messages.add({'role': 'ai', 'text': responseText});
      });
    }
  }
}
