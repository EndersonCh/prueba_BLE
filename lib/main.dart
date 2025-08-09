// main.dart
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'screens/bluetooth_off_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatefulWidget {
  const FlutterBlueApp({super.key});

  @override
  State<FlutterBlueApp> createState() => _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _adapterState == BluetoothAdapterState.on
          ? const ScanAndControlScreen()
          : BluetoothOffScreen(adapterState: _adapterState),
    );
  }
}

class ScanAndControlScreen extends StatefulWidget {
  const ScanAndControlScreen({super.key});

  @override
  State<ScanAndControlScreen> createState() => _ScanAndControlScreenState();
}

class _ScanAndControlScreenState extends State<ScanAndControlScreen> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _ledCharacteristic;
  final String targetDeviceName = "XIAO_ESP32_C3_LED";
  final Guid serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  String _botonStatus = "Esperando señal del botón...";

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  // main.dart

  void connectToDevice(BluetoothDevice device) async {
    // Es buena idea mostrar un indicador de "Conectando..." aquí si quieres.
    await FlutterBluePlus.stopScan();

    try {
      await device.connect();
    } catch (e) {
      debugPrint("Error al conectar: $e");
      // Aquí podrías mostrar un snackbar o alerta al usuario.
      return; // Salir de la función si la conexión falla
    }

    // 1. DESCUBRE SERVICIOS DESPUÉS DE CONECTAR
    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? foundCharacteristic;

    // Busca la característica que necesitas
    for (var service in services) {
      if (service.uuid == serviceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == characteristicUuid) {
            foundCharacteristic = characteristic;
            break; // Característica encontrada, sal del bucle
          }
        }
      }
      if (foundCharacteristic != null) {
        break; // Servicio encontrado, sal del bucle
      }
    }

    // 2. VERIFICA SI LA CARACTERÍSTICA FUE ENCONTRADA
    if (foundCharacteristic == null) {
      debugPrint("Característica no encontrada. Desconectando.");
      await device.disconnect();
      return;
    }

    // 3. ACTUALIZA EL ESTADO UNA SOLA VEZ CON TODOS LOS DATOS
    // Esto causará que la UI se reconstruya y muestre la pantalla de control.
    setState(() {
      _connectedDevice = device;
      _ledCharacteristic = foundCharacteristic;
      // El valor de _botonStatus ya es "Esperando señal del botón..." por defecto.
    });

    // 4. CONFIGURA LAS NOTIFICACIONES DESPUÉS DE QUE LA UI ESTÉ LISTA
    await _ledCharacteristic!.setNotifyValue(true);
    _ledCharacteristic!.onValueReceived.listen((value) {
      String received = String.fromCharCodes(value);
      debugPrint("📩 Notificación recibida: $received");
      debugPrint("Rebuild con estado: $_botonStatus");
      if (received.trim().contains("SOS")) {
        // Esta llamada a setState ahora funcionará correctamente
        // porque el widget ya está en la pantalla.
        debugPrint("Rebuild con estado: $_botonStatus");
        setState(() {
          _botonStatus = "Botón presionado por 3 segundos";
        });
        debugPrint("Rebuild con estado: $_botonStatus");
      }
    });
  }

  void toggleLed(bool turnOn) async {
    if (_ledCharacteristic != null) {
      await _ledCharacteristic!.write([turnOn ? 49 : 48]); // '1' or '0'
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectedDevice != null && _ledCharacteristic != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Controlar LED")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _botonStatus,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors
                      .black, // Aumenté un poco el tamaño para que sea más visible
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign
                    .center, // Buena práctica para textos de varias líneas
              ),

              const SizedBox(
                height: 32,
              ), // Aumenté el espacio para separar mejor

              ElevatedButton(
                onPressed: () => toggleLed(true),
                child: const Text("Encender LID"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => toggleLed(false),
                child: const Text("Apagar LED"),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("Escaneando dispositivos")),
        body: StreamBuilder<List<ScanResult>>(
          stream: FlutterBluePlus.scanResults,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final devices = snapshot.data!;
            return ListView(
              children: devices.map((r) {
                final name = r.device.platformName;
                if (name == targetDeviceName) {
                  return ListTile(
                    title: Text(name),
                    subtitle: Text(r.device.remoteId.str),
                    onTap: () => connectToDevice(r.device),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }).toList(),
            );
          },
        ),
      );
    }
  }
}

Future<void> requestPermissions() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.location,
  ].request();
}
