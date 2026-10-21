import 'package:flutter/material.dart';


import '../shell/main_shell.dart';
import 'confirm_step.dart';
import 'wifi_step.dart';
import 'zone_step.dart';
import '../data/cloud_store.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.onFinished});
  final void Function(String nickname)? onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _controller = PageController();
  int _page = 0;

  String _network = 'Home_Network_5G';
  String _zone = 'Kitchen';
  String _nickname = 'Main Kitchen Smoke Sensor #01';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) {
    setState(() => _page = page);
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Future<void> _enterDashboard() async {
    CloudStore.instance.setOnboardingDone(true);
    if (!mounted) return;
    final done = widget.onFinished;
    if (done != null) {
      done(_nickname);
      return;
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _go(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              WifiStep(
                onContinue: (network) {
                  setState(() => _network = network);
                  _go(1);
                },
              ),
              ZoneStep(
                wifiName: _network,
                onChangeWifi: () => _go(0),
                onConfirm: (zone, nickname) {
                  setState(() {
                    _zone = zone;
                    _nickname = nickname;
                  });
                  _go(2);
                },
              ),
              ConfirmStep(
                zone: _zone,
                nickname: _nickname,
                onEnter: _enterDashboard,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
