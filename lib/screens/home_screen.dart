import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_off_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothAdapterState>(
      stream: FlutterBluePlus.adapterState,
      initialData: BluetoothAdapterState.unknown,
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (state == BluetoothAdapterState.on) {
          return const ScanScreen();
        } else {
          return BluetoothOffScreen(
            adapterState: state ?? BluetoothAdapterState.unknown,
          );
        }
      },
    );
  }
}
