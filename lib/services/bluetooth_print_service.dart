import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class BluetoothPrintService extends ChangeNotifier {
  List<BluetoothInfo> _devices = [];
  String? _connectedDeviceId; // MAC address
  bool _isConnected = false;
  int _paperSize = 58; // 58mm or 80mm
  CapabilityProfile? _profile;

  List<BluetoothInfo> get devices => _devices;
  String? get connectedDeviceId => _connectedDeviceId;
  bool get isConnected => _isConnected;
  int get paperSize => _paperSize;

  BluetoothPrintService() {
    _init();
  }

  void _init() {
    // Check connection status?
    // print_bluetooth_thermal doesn't have a stream for status changes easily accessbile in init
    // We can assume disconnected or try to get connection status.
    PrintBluetoothThermal.connectionStatus.then((status) {
      _isConnected = status;
      notifyListeners();
    });
  }

  Future<void> scan() async {
    try {
      final List<BluetoothInfo> list =
          await PrintBluetoothThermal.pairedBluetooths;
      _devices = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Error scanning devices: $e');
    }
  }

  Future<void> connect(String macAddress) async {
    if (_connectedDeviceId == macAddress && _isConnected) return;

    try {
      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      );
      if (result) {
        _connectedDeviceId = macAddress;
        _isConnected = true;
      } else {
        _isConnected = false;
        debugPrint("Connection failed");
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _connectedDeviceId = null;
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  void setPaperSize(int size) {
    _paperSize = size;
    notifyListeners();
  }

  Future<void> printReceipt(Order order) async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (!connectionStatus) {
      // If we thought we were connected, update state
      if (_isConnected) {
        _isConnected = false;
        notifyListeners();
      }
      debugPrint("Not connected");
      return;
    }

    _profile ??= await CapabilityProfile.load();

    final generator = Generator(
      _paperSize == 58 ? PaperSize.mm58 : PaperSize.mm80,
      _profile!,
    );
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      'Resto POS',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.reset();

    bytes += generator.text(
      'Jl. Raya Kedung Baruk No.98,\nSurabaya. Telp: (031) 8721731',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    // Order Info
    bytes += generator.text(
      'No    : ${order.id}',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Kasir : Admin',
      styles: const PosStyles(align: PosAlign.left),
    );

    String dateStr = "-";
    try {
      final dt = DateTime.parse(order.orderDate.toString());
      dateStr = DateFormat('dd-MM-yyyy HH:mm:ss').format(dt);
    } catch (e) {
      dateStr = order.orderDate.toString();
    }
    bytes += generator.text(
      'Tgl   : $dateStr',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.hr();

    // Items
    final fmtApi = NumberFormat.decimalPattern('id');
    String fmt(num n) => fmtApi.format(n).replaceAll(',', '.');

    for (var item in order.orderItems) {
      bytes += generator.text(
        item.menuName,
        styles: const PosStyles(align: PosAlign.left),
      );

      String left = "${fmt(item.priceAtTime)} x ${fmt(item.quantity)}";
      String right = fmt(item.subtotal);

      bytes += generator.row([
        PosColumn(text: left, width: 8),
        PosColumn(
          text: right,
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    // Totals
    String total = fmt(order.totalAmount);
    bytes += generator.row([
      PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: total,
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.row([
      PosColumn(text: order.paymentMethod, width: 6),
      PosColumn(
        text: total,
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();

    // Footer
    bytes += generator.text(
      'Terima kasih',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Silahkan datang kembali',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);

    await PrintBluetoothThermal.writeBytes(bytes);
  }
}
