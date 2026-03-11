import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class GpsSocketService {
  WebSocketChannel? _channel;

  // Path bisa "/" atau "/geofencing" sesuai kebutuhan
  Stream<dynamic> connect({required String vehicleId, required String deviceType}) {
    // Format URL: ws://IP:PORT/PATH?vehicle_id=VALUE&device=VALUE
    final String wsUrl = 'ws://203.100.57.59:3300/?vehicle_id=$vehicleId&device=$deviceType';
    
    print("Connecting to: $wsUrl");
    
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    return _channel!.stream;
  }

  void disconnect() {
    _channel?.sink.close();
  }
}