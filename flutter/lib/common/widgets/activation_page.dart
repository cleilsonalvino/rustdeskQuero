import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';

/// Gate that blocks the main UI until a valid QueroDesk activation key is entered.
class ActivationGate extends StatefulWidget {
  final Widget child;
  final bool startServiceOnUnlock;

  const ActivationGate({
    Key? key,
    required this.child,
    this.startServiceOnUnlock = false,
  }) : super(key: key);

  static bool isActivated() {
    try {
      return bind.mainGetLocalOption(key: kOptionQuerodeskActivated) == 'Y';
    } catch (_) {
      return false;
    }
  }

  @override
  State<ActivationGate> createState() => _ActivationGateState();
}

class _ActivationGateState extends State<ActivationGate> {
  late bool _activated;

  @override
  void initState() {
    super.initState();
    _activated = ActivationGate.isActivated();
  }

  Future<void> _onUnlocked() async {
    await bind.mainSetLocalOption(key: kOptionQuerodeskActivated, value: 'Y');
    if (widget.startServiceOnUnlock) {
      gFFI.serverModel.startService();
    }
    if (mounted) {
      setState(() => _activated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activated) return widget.child;
    return ActivationPage(onUnlocked: _onUnlocked);
  }
}

class ActivationPage extends StatefulWidget {
  final Future<void> Function() onUnlocked;

  const ActivationPage({Key? key, required this.onUnlocked}) : super(key: key);

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Informe a chave de ativação');
      return;
    }
    if (key != kQuerodeskActivationKey) {
      setState(() => _error = 'Chave inválida');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onUnlocked();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF1A0B2E),
                    Color(0xFF2D1054),
                    Color(0xFF6700A2),
                  ]
                : const [
                    Color(0xFF9B4DEE),
                    Color(0xFF6700A2),
                    Color(0xFFE0457B),
                  ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: MyTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          size: 34,
                          color: MyTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'QueroDesk',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Digite a chave de ativação para continuar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MyTheme.darkGray,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      obscureText: _obscure,
                      enabled: !_busy,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Chave de ativação',
                        hintText: 'Cole ou digite a chave',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        errorText: _error,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyTheme.accent,
                          foregroundColor: Colors.white,
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Ativar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quero Delivery',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MyTheme.darkGray,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
