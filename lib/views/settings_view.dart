import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_print_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothPrintService>().scan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final printService = context.watch<BluetoothPrintService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Printer Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // -- Device Selection --
            const Text(
              'Bluetooth Device',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text("Select Printer"),
                    value: printService
                        .connectedDeviceId, // This is the mac address now
                    items: printService.devices.map((device) {
                      return DropdownMenuItem(
                        value: device.macAdress,
                        child: Text(device.name),
                      );
                    }).toList(),
                    onChanged: (mac) {
                      if (mac != null) {
                        printService.connect(mac);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    printService.scan();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: "Scan Devices",
                ),
              ],
            ),
            if (printService.isConnected)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Connected",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // -- Paper Size Selection --
            const Text(
              'Paper Size',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              value: printService.paperSize,
              items: const [
                DropdownMenuItem(value: 58, child: Text("58mm")),
                DropdownMenuItem(value: 80, child: Text("80mm")),
              ],
              onChanged: (val) {
                if (val != null) {
                  printService.setPaperSize(val);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "Note: Ensure Bluetooth is enabled and the printer is paired in system settings.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
