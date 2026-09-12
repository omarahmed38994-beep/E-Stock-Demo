import 'package:flutter/material.dart';
import '../services/misc_services.dart';
import '../theme/app_colors.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage(this.text, this.isUser);
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final AssistantService _service = AssistantService();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  static const _suggestions = [
    'Which branch needs attention?',
    'What are my top-selling products?',
    'What products are low in stock?',
    'Which products may run out soon?',
    'Show me the most profitable categories.',
    'Why did sales decrease this week?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      "Hi! I'm your StockVision business assistant. Ask me about branch performance, sales, "
      "inventory, or profitability — I'll answer using your real business data.",
      false,
    ));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await _service.ask(text);
      setState(() {
        _messages.add(_ChatMessage(result['answer'] as String, false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage("I couldn't reach the server. Please check your connection and try again.", false));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.smart_toy_outlined, size: 20),
          const SizedBox(width: 8),
          const Text('Ask your business'),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                ..._messages.map((m) => _MessageBubble(message: m)),
                if (_loading) const _TypingIndicator(),
              ],
            ),
          ),
          if (_messages.length <= 1)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _suggestions.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => _send(s),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: Text(s, style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Ask a question about your business...'),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white), onPressed: () => _send(_controller.text)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: message.isUser ? null : Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
        ),
        child: Text(message.text, style: TextStyle(color: message.isUser ? Colors.white : null, fontSize: 13.5, height: 1.4)),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200)),
        child: const SizedBox(width: 20, height: 12, child: Center(child: SizedBox(height: 8, width: 8, child: CircularProgressIndicator(strokeWidth: 2)))),
      ),
    );
  }
}
