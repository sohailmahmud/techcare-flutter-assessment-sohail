import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A small banner shown at the top of the app when the device is offline.
/// It listens to the Connectivity stream and shows/hides accordingly.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, this.child});

  final Widget? child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late Stream<ConnectivityResult> _connectivityStream;
  ConnectivityResult _current = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((result) {
      setState(() {
        _current = result;
      });
    });
    // Check initial state
    Connectivity().checkConnectivity().then((initial) {
      setState(() {
        _current = initial;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _current == ConnectivityResult.wifi || _current == ConnectivityResult.mobile;
    final banner = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOnline ? 0 : 28,
      color: Colors.redAccent,
      alignment: Alignment.center,
      child: isOnline
          ? const SizedBox.shrink()
          : const Text(
              'Offline — some actions will be queued',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        banner,
        Expanded(child: widget.child ?? const SizedBox.shrink()),
      ],
    );
  }
}
