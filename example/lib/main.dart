import 'package:camcode/cam_code_scanner.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      routes: {
        '/': (context) => MyApp(),
      },
      initialRoute: '/',
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String barcodeValue = 'Press button to scan a barcode';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.scanner),
          onPressed: () => openScanner(context, _onResult),
        ),
        appBar: AppBar(
          title: const Text('CamCode example app'),
        ),
        body:CamCodeScannerPage(_onResult),
      ),
    );
  }

  void _onResult(String result) {
    setState(() {
      barcodeValue = result;
    });
  }

  void openScanner(BuildContext context, Function(String) onResult) {
    showDialog(
      context: context,
      builder: (context) => CamCodeScannerPage(_onResult),
    );
  }
}

class CamCodeScannerPage extends StatefulWidget {
  final Function(String) onResult;

  CamCodeScannerPage(this.onResult);

  @override
  _CamCodeScannerPageState createState() => _CamCodeScannerPageState();
}

class _CamCodeScannerPageState extends State<CamCodeScannerPage> {
  /// Create a controller to send instructions to scanner
  final CamCodeScannerController _controller = CamCodeScannerController();

  /// List of availables cameras
  final List<String> cameraNames = [];

  /// currently selected camera
  late String _selectedCamera;

  @override
  void initState() {
    super.initState();
    _fetchDeviceList();
  }

  void _fetchDeviceList() async {
    /// Get list of available cameras
    final cameras = await _controller.fetchDeviceList();
    setState(() {
      cameraNames.addAll(cameras);
      _selectedCamera = cameras.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 800,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(width: 1.0)
              ),
              child: CamCodeScanner(
                width: 800,
                height: 200,
                refreshDelayMillis: 16,
                onBarcodeResult: (barcode) {
                  widget.onResult(barcode);
                },
                showScannerLine: false,
                controller: _controller,
                showDebugFrames: false,
              ),
            ),
          ),
          Positioned(
            bottom: 48.0,
            left: 48.0,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _controller.releaseResources();
                  },
                  child: Text('Release resources'),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () {
                    _controller.pauseCamera();
                  },
                  child: Text('Pause'),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () {
                    _controller.playCamera();
                  },
                  child: Text('Play'),
                ),
                cameraNames.isEmpty
                    ? Container()
                    : DropdownButton(
                        items: cameraNames
                            .map(
                              (name) => DropdownMenuItem(
                                child: Text(name),
                                value: name,
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            _controller.selectDevice(value);
                            setState(() {
                              _selectedCamera = value;
                            });
                          }
                        },
                        value: _selectedCamera,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
