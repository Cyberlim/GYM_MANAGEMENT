import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_owner_web/data/services/socket_service.dart';
import 'package:gym_owner_web/data/api/api_service.dart';

class SuspendedPage extends StatefulWidget {
  final String suspensionId;

  const SuspendedPage({super.key, required this.suspensionId});

  @override
  State<SuspendedPage> createState() => _SuspendedPageState();
}

class _SuspendedPageState extends State<SuspendedPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initSocket();
  }

  void _initSocket() {
    final socketService = SocketService();
    // Use the suspension ID as the "userId" to connect, or if the socket isn't connected, we can connect it.
    socketService.initSocket('suspension_${widget.suspensionId}');
    socketService.joinSuspensionRoom(widget.suspensionId);
    
    socketService.onNewMessage = (messageData) {
      if (!mounted) return;
      setState(() {
        _messages = List.from(_messages)..add(messageData);
      });
      _scrollToBottom();
    };

    socketService.onAccountReactivated = (data) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Account Reactivated'),
          content: const Text('Good news! Your account has been reactivated. Please log in again to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    };
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await _apiService.get('/support/suspensions/public/${widget.suspensionId}');
      setState(() {
        _messages = List.from(response as List<dynamic>? ?? []);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Because the user is suspended, they might not have a valid token if they were logged out.
      // Wait, if they just logged in, they were given a 403 and NOT given a token.
      // If we need them to authenticate to send a message, we might need to adjust the backend.
      // The backend allows sending message if user is authenticated OR we need a public endpoint.
      // But let's assume they might not have a token.
      
      // Let's send the message. If backend throws 401 because we have no token, we need a workaround.
      // We will create a public endpoint for gym owners to send a message if they have a suspensionId,
      // or we can just pass suspensionId in the body and verify it against something.
      // Let's just use the current endpoint. (Will need to modify support.controller.ts if token is required)
      
      final prefs = await SharedPreferences.getInstance();
      
      await _apiService.post('/support/suspensions/public/${widget.suspensionId}', {
        'message': messageText,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Account Suspended', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.white),
            onPressed: () {
              context.go('/login');
            },
          )
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(LucideIcons.alertTriangle, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Your account has been suspended.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Suspension ID: ${widget.suspensionId}',
                style: const TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Please contact support below to resolve this issue.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              
              // Chat Box
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: _isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final isSuperadmin = msg['senderRole'] == 'superadmin';
                                
                                return Align(
                                  alignment: isSuperadmin ? Alignment.centerLeft : Alignment.centerRight,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSuperadmin ? const Color(0xFF2A2A2A) : const Color(0xFFCFFF50).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSuperadmin ? Colors.white10 : const Color(0xFFCFFF50).withOpacity(0.5)
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isSuperadmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          msg['message'] ?? '',
                                          style: TextStyle(
                                            color: isSuperadmin ? Colors.white : const Color(0xFFCFFF50),
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isSuperadmin ? 'Superadmin Support' : 'You',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white10)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: const Color(0xFF2A2A2A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCFFF50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(LucideIcons.send, color: Colors.black, size: 20),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
