import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:poss_mobile_app/components/toast_widget.dart';
import 'package:poss_mobile_app/services/api_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ReverbService {
  late WebSocketChannel _channel;

  // ─── Config ───────────────────────────────────────────────────────────────
  final String appKey = "upxom68il3bzhqdbwmbj";
  final String host   = "192.168.230.198";
  final int    wsPort = 8080;   // Reverb WebSocket port
  final int    apiPort = 8000;  // Laravel HTTP port
  final bool   useSSL = false;

  // ─── State ────────────────────────────────────────────────────────────────
  final Map<String, void Function(dynamic)> _eventHandlers = {};
  final List<String> _pendingPrivateChannels = [];
  final Set<String>  _subscribedChannels     = {};

  String? _socketId;
  bool    _isConnected = false;

  Timer?  _pingTimer;
  Timer?  _reconnectTimer;
  int     _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay  = Duration(seconds: 3);
  static const Duration _pingInterval    = Duration(seconds: 30);

  // ─── Connect ──────────────────────────────────────────────────────────────

  void connect() {
    final scheme = useSSL ? 'wss' : 'ws';
    final url =
        '$scheme://$host:$wsPort/app/$appKey'
        '?protocol=7&client=js&version=4.4.0&flash=false';

    print('[Reverb] Connecting to $url');

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(url));
    } catch (e) {
      print('[Reverb] Failed to create channel: $e');
      _scheduleReconnect();
      return;
    }

    _channel.stream.listen(
      _handleMessage,
      onError: (error) {
        print('[Reverb] Stream error: $error');
        _onDisconnected();
      },
      onDone: () {
        print('[Reverb] Connection closed');
        _onDisconnected();
      },
    );
  }

  // ─── Message handler ──────────────────────────────────────────────────────

  void _handleMessage(dynamic raw) {
    print('[Reverb] ← $raw');

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw as String);
    } catch (e) {
      print('[Reverb] Failed to parse message: $e');
      return;
    }

    final event = data['event'] as String?;
    if (event == null) return;

    switch (event) {

      // Handshake
      case 'pusher:connection_established':
        final payload = jsonDecode(data['data'] as String);
        _socketId    = payload['socket_id'] as String?;
        _isConnected = true;
        _reconnectAttempts = 0;
        print('[Reverb] Connected — socket_id: $_socketId');
        _startPingTimer();
        _flushPendingChannels();
        break;

      // Server-initiated ping
      case 'pusher:ping':
        _send({"event": "pusher:pong", "data": {}});
        print('[Reverb] Pong sent');
        break;

      // Our own pong coming back (some servers echo it)
      case 'pusher:pong':
        print('[Reverb] Pong received');
        break;

      // Successful subscription confirmation
      case 'pusher:subscription_succeeded':
        final channel = data['channel'] as String?;
        print('[Reverb] Subscription confirmed: $channel');
        break;

      // Subscription error
      case 'pusher:subscription_error':
        print('[Reverb] Subscription error: $data');
        break;

      // Custom / app events
      default:
        _routeEvent(event, data);
    }
  }

  // ─── Event routing ────────────────────────────────────────────────────────

  void _routeEvent(String event, Map<String, dynamic> data) {
    if (!_eventHandlers.containsKey(event)) {
      print('[Reverb] Unhandled event: $event');
      return;
    }

    dynamic payload = data['data'];
    if (payload is String) {
      try {
        payload = jsonDecode(payload);
      } catch (_) {
        // Leave as string if not JSON
      }
    }

    _eventHandlers[event]!(payload);

    if (!event.startsWith('pusher:')) {
      toast('Event $event received: $payload');
    }
  }

  // ─── Subscribe (public) ───────────────────────────────────────────────────

  void subscribe(String channelName) {
    if (!_isConnected || _socketId == null) {
      print('[Reverb] Not connected — queuing public channel: $channelName');
      _pendingPrivateChannels.add(channelName);
      return;
    }

    if (_subscribedChannels.contains(channelName)) {
      print('[Reverb] Already subscribed to: $channelName');
      return;
    }

    _send({
      "event": "pusher:subscribe",
      "data": {"channel": channelName},
    });

    _subscribedChannels.add(channelName);
    print('[Reverb] Subscribed (public): $channelName');
  }

  // ─── Subscribe (private) ──────────────────────────────────────────────────

  Future<void> subscribePrivate(String channelName) async {
    // Ensure channel name has the "private-" prefix
    final fullChannelName = channelName.startsWith('private-')
        ? channelName
        : 'private-$channelName';

    if (!_isConnected || _socketId == null) {
      print('[Reverb] Not connected — queuing private channel: $fullChannelName');
      if (!_pendingPrivateChannels.contains(fullChannelName)) {
        _pendingPrivateChannels.add(fullChannelName);
      }
      return;
    }

    if (_subscribedChannels.contains(fullChannelName)) {
      print('[Reverb] Already subscribed to: $fullChannelName');
      return;
    }

    try {
      final token = await APIService.getToken();
      print(token);

      if (token == null || token.isEmpty) {
        print('[Reverb] ERROR: No auth token available');
        return;
      }

      print('[Reverb] Authenticating channel: $fullChannelName');

      final response = await http.post(
        Uri.parse('http://$host:$apiPort/api/broadcasting/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',  // ← Critical: tells Laravel to return JSON
        },
        body: jsonEncode({
          'channel_name': fullChannelName,
          'socket_id': _socketId,
        }),
      ).timeout(const Duration(seconds: 10));

      print('[Reverb] Auth status : ${response.statusCode}');
      print('[Reverb] Auth body   : "${response.body}"');

      // Guard: empty body
      if (response.body.isEmpty) {
        print('[Reverb] ERROR: Empty auth response body (status ${response.statusCode}). '
            'Check that /api/broadcasting/auth is in routes/api.php '
            'and your Bearer token is valid.');
        return;
      }

      // Guard: non-200
      if (response.statusCode != 200) {
        print('[Reverb] ERROR: Auth failed — ${response.statusCode}: ${response.body}');
        return;
      }

      final Map<String, dynamic> authData;
      try {
        authData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('[Reverb] ERROR: Auth response is not valid JSON: ${response.body}');
        return;
      }

      // Guard: missing auth key
      final authSignature = authData['auth'];
      if (authSignature == null) {
        print('[Reverb] ERROR: Auth response missing "auth" key: $authData');
        return;
      }

      // Send subscribe event with auth signature
      _send({
        "event": "pusher:subscribe",
        "data": {
          "channel": fullChannelName,
          "auth": authSignature,
        },
      });

      _subscribedChannels.add(fullChannelName);
      print('[Reverb] Subscribed (private): $fullChannelName');

    } on TimeoutException {
      print('[Reverb] ERROR: Auth request timed out for $fullChannelName');
    } catch (e) {
      print('[Reverb] ERROR: subscribePrivate exception: $e');
    }
  }

  // ─── Register event listener ──────────────────────────────────────────────

  /// Register a listener for an event.
  ///
  /// For private channels with broadcastAs(), prefix the event name
  /// with a dot, e.g. '.order.added'.
  void on(String eventName, void Function(dynamic data) callback) {
    _eventHandlers[eventName] = callback;
    print('[Reverb] Listener registered: $eventName');
  }

  /// Remove a previously registered listener.
  void off(String eventName) {
    _eventHandlers.remove(eventName);
    print('[Reverb] Listener removed: $eventName');
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  void _send(Map<String, dynamic> payload) {
    try {
      _channel.sink.add(jsonEncode(payload));
      print('[Reverb] → ${payload['event']}');
    } catch (e) {
      print('[Reverb] Failed to send: $e');
    }
  }

  void _flushPendingChannels() {
    if (_pendingPrivateChannels.isEmpty) return;
    print('[Reverb] Flushing ${_pendingPrivateChannels.length} pending channel(s)');
    final pending = List<String>.from(_pendingPrivateChannels);
    _pendingPrivateChannels.clear();
    for (final ch in pending) {
      subscribePrivate(ch);
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_isConnected) {
        _send({"event": "pusher:ping", "data": {}});
      }
    });
  }

  void _onDisconnected() {
    _isConnected = false;
    _socketId    = null;
    _pingTimer?.cancel();

    // Re-queue subscribed channels so they re-subscribe after reconnect
    for (final ch in _subscribedChannels) {
      if (!_pendingPrivateChannels.contains(ch)) {
        _pendingPrivateChannels.add(ch);
      }
    }
    _subscribedChannels.clear();

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[Reverb] Max reconnect attempts reached. Giving up.');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;

    print('[Reverb] Reconnecting in ${delay.inSeconds}s '
        '(attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(delay, connect);
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────

  void disconnect() {
    print('[Reverb] Disconnecting');
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _isConnected = false;
    _subscribedChannels.clear();
    _pendingPrivateChannels.clear();
    _eventHandlers.clear();
    _channel.sink.close();
  }
}