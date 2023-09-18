import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    requestPermission();
    initBleList();
  }

  // final flutterBlue = FlutterBlue.instance;
  List<BluetoothService>? bluetoothServices;
  List<ControlButton> controlButtons = [];
  Future<void> requestPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // Location permission granted, you can now use Bluetooth.
    } else {
      log(status.name);
      // openAppSettings();
      // Location permission denied.
      // You may want to handle this case gracefully or request permission again.
    }
  }

  //  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  final List<BluetoothDevice> _devicesList = [];
  Future initBleList() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothAdvertise.request();
    FlutterBluePlus.connectedSystemDevices.asStream().listen((devices) {
      for (var device in devices) {
        _addDeviceTolist(device);
      }
    });
    FlutterBluePlus.scanResults.listen((scanResults) {
      for (var result in scanResults) {
        _addDeviceTolist(result.device);
      }
    });
    FlutterBluePlus.startScan();
  }

  void _addDeviceTolist(BluetoothDevice device) {
    if (!_devicesList.contains(device)) {
      setState(() {
        _devicesList.add(device);
      });
    }
  }

  var data = [""];
  checkscan() async {
    // flutterBlue.startScan(timeout: const Duration(seconds: 4));

// Listen for scan results
// FlutterBluePlus.scanResults.listen((scanResult) {
//   // Check if the device meets your criteria (e.g., service or name)
//   if (scanResult.device.name == 'YourSmartWatchName') {
//     // Connect to the device
//     scanResult.device.connect();
//   }
// });

// // Stop scanning after a while
// await Future.delayed(Duration(seconds: 4));
// flutterBlue.stopScan();
    // flutterblueplus packgae
    // FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    // var subscription = FlutterBluePlus.scanResults.listen((results) {
    //   for (ScanResult r in results) {
    //     log('${r.device.localName} found! rssi: ${r.rssi}');
    //     setState(() {
    //       data.add('${r.device.localName} found! rssi: ${r.rssi}');
    //     });
    //   }
    // });
    // setState(() {
    //   data.add(subscription.toString());
    // });

    // FlutterBluePlus.stopScan();

    // connect()async{
    //   final device = await flutterBlue.connect(device: scanResult.device);

// Discover services and characteristics
// List<BluetoothService> services = await device.discoverServices();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('Flutter BLE')),
            body: bluetoothServices == null
                ? _buildListViewOfDevices()
                : _buildControlButtons())

        // Scaffold(
        //   appBar: AppBar(),
        //   floatingActionButton: FloatingActionButton(onPressed: () async {
        //     checkscan();
        //   }),
        //   body: Center(
        //     child: StreamBuilder<BluetoothAdapterState>(
        //         stream: FlutterBluePlus.adapterState,
        //         initialData: BluetoothAdapterState.unknown,
        //         builder: (c, snapshot) {
        //           final adapterState = snapshot.data;
        //           if (adapterState == BluetoothAdapterState.on) {
        //             return ListView.builder(
        //               itemCount: data.length,
        //               itemBuilder: (context, index) {
        //                 return Text(data[index]);
        //               },
        //             );
        //           } else {
        //             FlutterBluePlus.stopScan();
        //             return const Text("Bluetooth stoped");
        //           }
        //         }),
        //   ),
        // ),
        );
  }

  ListView _buildListViewOfDevices() {
    List<Widget> containers = [];
    for (BluetoothDevice device
        in _devicesList.where((element) => element.localName.isNotEmpty)) {
      containers.add(
        SizedBox(
          height: 60,
          child: Row(
            children: <Widget>[
              Expanded(
                  child: Column(children: <Widget>[
                Text(device.localName),
                Text(device.remoteId.toString())
              ])),
              ElevatedButton(
                child: const Text('Connect',
                    style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  // readDataFromDevice(
                  //     device, "00002a01-0000-1000-8000-00805f9b34fb");

                  try {
                    await device.connect();
                    Get.snackbar("Title", "Connected");

                    // Discover services
                    List<BluetoothService> services =
                        await device.discoverServices();
                    setState(() {
                      bluetoothServices = services;
                    });

                    // controlButtons.addAll([
                    //   ControlButton(
                    //       buttonName: 'Read',
                    //       onTap: () => readDataFromDevice(
                    //           device, "00002a25-0000-1000-8000-00805f9b34fb")),
                    //   ControlButton(
                    //       buttonName: 'first	',
                    //       onTap: () => readDataFromDevice(
                    //           device, "00002a27-0000-1000-8000-00805f9b34fb")),
                    // ]);
                    // Read characteristic UUIDs
                    readAllCharacteristicUUIDs(device);
                  } catch (e) {
                    // Handle connection or discovery errors here
                    print("Error: $e");
                    await device.disconnect();
                  }
                },
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
        padding: const EdgeInsets.all(8), children: <Widget>[...containers]);
  }

  Future<void> writeValue(List<int> value) async {
    BluetoothService? bluetoothService = bluetoothServices?.firstWhere(
        (element) =>
            element.uuid.toString() == '0000fea6-0000-1000-8000-00805f9b34fb');
    BluetoothCharacteristic? bluetoothCharacteristic =
        bluetoothService?.characteristics.firstWhere((element) =>
            element.uuid.toString() == 'b5f90072-aa8d-11e3-9046-0002a5d5c51b');
    bluetoothCharacteristic?.write(value);
  }

  Future<void> readValue(String characteristicUUID) async {
    BluetoothService? bluetoothService = bluetoothServices?.firstWhere(
        (element) =>
            element.uuid.toString() == '00001800-0000-1000-8000-00805f9b34fb');

    BluetoothCharacteristic? bluetoothCharacteristic =
        bluetoothService?.characteristics.firstWhere((element) =>
            element.uuid.toString() ==
            '0000$characteristicUUID-0000-1000-8000-00805f9b34fb');
    List<int>? utf8Response = await bluetoothCharacteristic?.read();
    setState(() {
      readableValue = utf8.decode(utf8Response ?? []);
    });
  }

  Future<void> readAllCharacteristicUUIDs(device) async {
    for (BluetoothService service in bluetoothServices!) {
      log(service.uuid.toString(), name: "Service UUID");
      // Get.snackbar('Service UUID:', ' ${service.uuid}');
      charactersticslist.add('UUID-${service.uuid}');
      controlButtons.add(ControlButton(buttonName: 'Skipp', onTap: () => {}));
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        log(characteristic.uuid.toString(), name: "Characteristic UUID:");
        charactersticslist.add('${characteristic.characteristicUuid}');
        controlButtons.add(ControlButton(
            buttonName: 'Read',
            onTap: () => readDataFromDevice(device,
                "${characteristic.characteristicUuid}", "${service.uuid}")));
        // Get.snackbar('Characteristic UUID:', ' ${characteristic.uuid}');
      }
      setState(() {});
    }
  }

  String? readableValue;
  List<String> charactersticslist = [];
  Widget _buildControlButtons() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            children: controlButtons
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: ElevatedButton(
                          onPressed: e.onTap, child: Text(e.buttonName)),
                    ))
                .toList(),
          ),
          Center(
              child: Column(
            children: [
              Text(readableValue ?? 'Values'),
              ...charactersticslist.map((e) => Text(e))
            ],
          )),
        ],
      ),
    );
  }

  Future<void> readDataFromDevice(
      BluetoothDevice device, String characteristicUUID, String suuid) async {
    try {
      BluetoothService service = bluetoothServices!.firstWhere(
        (s) => s.uuid.toString() == suuid,
        orElse: () => throw Exception('Service not found'),
      );

      // ignore: unnecessary_null_comparison
      if (service != null) {
        BluetoothCharacteristic characteristic =
            service.characteristics.firstWhere(
          (c) => c.uuid.toString() == characteristicUUID,
          orElse: () => throw Exception('Characterstic not found'),
        );

        if (characteristic != null) {
          // Read data from the characteristic
          List<int> data = await characteristic.read();
          // Process and use the data as needed
          String readableData = utf8.decode(data);

          readableValue = readableData;
          charactersticslist.add('Read data without:' ' $data');
          charactersticslist.add(readableData);
          Get.snackbar('Read data:', ' $readableData');
        } else {
          Get.snackbar('Characteristic not found.', '');
        }
      } else {
        Get.snackbar('Service not found.', '');
      }
    } catch (e) {
      // Handle errors
      Get.snackbar('Error:', ' $e');
      charactersticslist.add(e.toString());
      setState(() {});
    } finally {
      // Disconnect from the device when done
      // await device.disconnect();
    }
  }
}

class ControlButton {
  final String buttonName;
  final Function() onTap;

  ControlButton({required this.buttonName, required this.onTap});
}
