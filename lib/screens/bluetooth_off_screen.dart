import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothOffScreen extends StatelessWidget {
  final BluetoothAdapterState adapterState;

  const BluetoothOffScreen({super.key, required this.adapterState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Apagado")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bluetooth_disabled,
              size: 100.0,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text('Por favor, enciende el Bluetooth para continuar.'),
            Text('Estado actual: $adapterState'),
          ],
        ),
      ),
    );
  }
}
