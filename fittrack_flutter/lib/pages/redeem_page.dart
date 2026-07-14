import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/redeem_service.dart';

class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});
  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final _controller = TextEditingController();
  bool _processing = false;

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    setState(() => _processing = true);
    final result = await RedeemService.instance.verifyAndRedeem(code);
    setState(() => _processing = false);

    String msg;
    switch (result) {
      case RedeemResult.success:
        msg = '兑换成功！已永久解锁 Pro';
        break;
      case RedeemResult.invalidFormat:
        msg = '格式错误：应为 FITT-XXXX-XXXX-XXXX';
        break;
      case RedeemResult.invalidSignature:
        msg = '兑换码无效';
        break;
      case RedeemResult.alreadyRedeemed:
        msg = '此兑换码已被使用';
        break;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (result == RedeemResult.success) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('兑换 Pro')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.card_giftcard, size: 64),
            const SizedBox(height: 16),
            const Text('输入兑换码以永久解锁 Pro 权益',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'FITT-XXXX-XXXX-XXXX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _processing ? null : _submit,
              child: _processing
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('立即兑换'),
            ),
          ],
        ),
      ),
    );
  }
}
