import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Camera barcode scanner widget
/// Asks for camera access permission
/// Shows camera images stream
/// Captures pictures every 'refreshDelayMillis'
/// Ask your favorite javascript library
/// to identify a barcode in the current picture
class CamCodeScanner extends StatefulWidget {
  /// shows the current analysing picture
  final bool showDebugFrames;

  /// call back to trigger on barcode result
  final Function onBarcodeResult;

  /// width dimension
  final double width;

  /// height dimension
  final double height;

  /// delay between to picture analysis
  final int refreshDelayMillis;

  /// controller to control the camera from outside
  final CamCodeScannerController? controller;

  /// The color of the background mask
  final Color backgroundColor;

  /// shows the current analysing picture
  final bool showScannerLine;

  /// Camera barcode scanner widget
  /// Params:
  /// * showDebugFrames [true|false] - shows the current analysing picture
  /// * onBarcodeResult - call back to trigger on barcode result
  /// * width, height - dimensions
  /// * refreshDelayMillis - delay between to picture analysis
  CamCodeScanner({
    this.showDebugFrames = false,
    required this.onBarcodeResult,
    required this.width,
    required this.height,
    this.refreshDelayMillis = 1000,
    this.controller,
    this.backgroundColor = Colors.black54,
    this.showScannerLine = true,
  });

  @override
  _CamCodeScannerState createState() => _CamCodeScannerState();
}

class _CamCodeScannerState extends State<CamCodeScanner> {
  /// communication channel between widget and platform code
  final MethodChannel channel = MethodChannel('camcode');
  final EventChannel eventChannel = EventChannel('camcode_event');

  /// Webcam widget to insert into the tree
  late Widget _webcamWidget;

  /// Debug frame Image widget to insert into the tree
  late Widget _imageWidget;

  /// The barcode result
  String barcode = '';

  /// Used to know if camera is loading or initialized
  bool initialized = false;

  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();

    initialize();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    // channel.invokeMethod(
    //   'releaseResources',
    // );
    super.dispose();
  }

  /// Calls the platform initialization and wait for result
  Future<void> initialize() async {
    final time = await channel.invokeMethod(
      'initialize',
      [
        widget.width,
        widget.height,
        widget.refreshDelayMillis,
      ],
    );

    // Create video widget
    _webcamWidget = HtmlElementView(
      key: UniqueKey(),
      viewType: 'webcamVideoElement$time',
    );

    _imageWidget = HtmlElementView(
      viewType: 'imageElement',
    );

    // Set the initialized flag
    setState(() {
      initialized = true;
    });

    _subscribeForResult();
    if (widget.controller?._channelCompleter.isCompleted != true) {
      widget.controller?._channelCompleter.complete(channel);
    }
  }

  /// Listen platform result
  void _subscribeForResult() {
    _streamSubscription?.cancel();
    _streamSubscription = eventChannel.receiveBroadcastStream().listen((onData) {
      onBarcodeResult(onData);
    });
  }

  /// Method called when a barcode is detected
  Future<void> onBarcodeResult(String _barcode) async {
    setState(() {
      barcode = _barcode;
    });
    widget.onBarcodeResult(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          await channel.invokeMethod('releaseResources');
          return true;
        },
        child: Builder(
          builder: (context) => Center(
            child: initialized
                ? Stack(
              children: <Widget>[
                SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: _webcamWidget,
                ),
                if (widget.showDebugFrames)
                  Positioned(
                    top: widget.height * .4,
                    left: 0,
                    child: SizedBox(
                      width: widget.width,
                      height: widget.height * .2,
                      child: _imageWidget,
                    ),
                  ),
                if (widget.showScannerLine)
                  Center(
                    child: CustomPaint(
                      size: Size(
                        widget.width,
                        widget.height * .2,
                      ),
                      painter: ScannerLine(
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            )
                : CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

/// Custom painter to draw the scanner line
class ScannerLine extends CustomPainter {
  /// Color of the line
  final Color color;

  ScannerLine({
    this.color = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/// Controller to control the camera from outside
class CamCodeScannerController {
  /// Channel to communicate with the platform code
  final Completer<MethodChannel> _channelCompleter = Completer();

  /// Invoke this method to close the camera and release all resources
  Future<void> releaseResources() async {
    final _channel = await _channelCompleter.future;
    return _channel.invokeMethod(
      'releaseResources',
    );
  }

  /// Waits for the device list completer result
  Future<List<String>> fetchDeviceList() async {
    final _channel = await _channelCompleter.future;
    final devices =
    await _channel.invokeMethod<List<dynamic>?>('fetchDeviceList');
    return devices?.map((e) => e.toString()).toList() ?? [];
  }

  /// Selects the device with the given device name
  Future<void> selectDevice(String device) async {
    final _channel = await _channelCompleter.future;
    return _channel.invokeMethod(
      'selectDevice',
      device,
    );
  }

  /// Invoke this method to pause camera
  Future<void> pauseCamera() async {
    final _channel = await _channelCompleter.future;
    return _channel.invokeMethod('pauseCamera');
  }

  /// Invoke this method to resume camera from pause state
  Future<void> resumeCamera() async {
    final _channel = await _channelCompleter.future;
    return _channel.invokeMethod('resumeCamera');
  }

  /// Invoke this method to stop camera
  Future<void> stopCamera() async {
    final _channel = await _channelCompleter.future;
    return _channel.invokeMethod('stopCamera');
  }

  /// Invoke this method to play camera
  Future<void> playCamera() async {
    final _channel = await _channelCompleter.future;
    return _channel.invokeMethod('resumeCamera');
  }
}