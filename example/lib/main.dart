import 'dart:async';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInChannel = false;
  final _infoStrings = <String>[];

  static final _sessions = List<VideoSession>();
  String dropdownValue = 'Off';

  final List<String> voices = [
    'Off',
    'Oldman',
    'BabyBoy',
    'BabyGirl',
    'Zhubajie',
    'Ethereal',
    'Hulk'
  ];

  /// remote user list
  final _remoteUsers = List<int>();

  @override
  void initState() {
    super.initState();

    _initAgoraRtcEngine();
    _addAgoraEventHandlers();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Agora Flutter SDK'),
        ),
        body: Container(
          child: Column(
            children: [
              Container(height: 320, child: _viewRows()),
              OutlineButton(
                child: Text(_isInChannel ? 'Leave Channel' : 'Join Channel',
                    style: textStyle),
                onPressed: _toggleChannel,
              ),
              Container(height: 100, child: _voiceDropdown()),
              Expanded(child: Container(child: _buildInfoList())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voiceDropdown() {
    return Scaffold(
      body: Center(
        child: DropdownButton<String>(
          value: dropdownValue,
          onChanged: (String newValue) {
            setState(() {
              dropdownValue = newValue;
              VoiceChanger voice =
                  VoiceChanger.values[(voices.indexOf(dropdownValue))];
              AgoraRtcEngine.setLocalVoiceChanger(voice);
            });
          },
          items: voices.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _initAgoraRtcEngine() async {
    AgoraRtcEngine.create('YOUR APP ID');

    AgoraRtcEngine.enableVideo();
    AgoraRtcEngine.enableAudio();
    // AgoraRtcEngine.setParameters('{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}}');
    AgoraRtcEngine.setChannelProfile(ChannelProfile.Communication);

    VideoEncoderConfiguration config = VideoEncoderConfiguration();
    config.orientationMode = VideoOutputOrientationMode.FixedPortrait;
    AgoraRtcEngine.setVideoEncoderConfiguration(config);
  }

  void _addAgoraEventHandlers() {
    AgoraRtcEngine.onJoinChannelSuccess =
        (String channel, int uid, int elapsed) {
      setState(() {
        String info = 'onJoinChannel: ' + channel + ', uid: ' + uid.toString();
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onLeaveChannel = () {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _remoteUsers.clear();
      });
    };

    AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
      setState(() {
        String info = 'userJoined: ' + uid.toString();
        _infoStrings.add(info);
        _remoteUsers.add(uid);
      });
    };

    AgoraRtcEngine.onUserOffline = (int uid, int reason) {
      setState(() {
        String info = 'userOffline: ' + uid.toString();
        _infoStrings.add(info);
        _remoteUsers.remove(uid);
      });
    };

    AgoraRtcEngine.onFirstRemoteVideoFrame =
        (int uid, int width, int height, int elapsed) {
      setState(() {
        String info = 'firstRemoteVideo: ' +
            uid.toString() +
            ' ' +
            width.toString() +
            'x' +
            height.toString();
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onRecordFrame = (Uint8List bytes, int numOfSamples, int bytesPerSample,
    int channels, int samplesPerSec){
      debugPrint("onRecordFrame 数据回来了哦->"+bytes.toString());

    };
    AgoraRtcEngine.onPlaybackFrame = (Uint8List bytes, int numOfSamples, int bytesPerSample,
    int channels, int samplesPerSec){
      debugPrint("onPlaybackFrame 数据回来了哦->"+bytes.toString());

    };
  }

  void _toggleChannel() async {
    // await for camera and mic permissions before pushing video page
    Map<Permission, PermissionStatus> list = await _handleCameraAndMic();
    bool isGranted = true;
    list.forEach((key, value) {
      print("权限内容$key=$value");

      if (!value.isGranted) {
        isGranted = false;
        print("拒绝=====");
        return;
      }
    });
    print("最终权限=$isGranted");
    if (!isGranted) {
      debugPrint("没有权限==");

      return;
    }

    if (_isInChannel) {
      await AgoraRtcEngine.leaveChannel();
      await AgoraRtcEngine.stopPreview();
    } else {
      await AgoraRtcEngine.startPreview();
      await AgoraRtcEngine.joinChannel(null, 'flutter', null, 0);
    }
    setState(() {
      _isInChannel = !_isInChannel;
    });
  }

  Widget _viewRows() {
    return Row(
      children: <Widget>[
        for (final widget in _renderWidget)
          Expanded(
            child: Container(
              child: widget,
            ),
          )
      ],
    );
  }


  Future<Map<Permission, PermissionStatus>> _handleCameraAndMic() async {
    return await [Permission.camera, Permission.microphone].request();
  }



  Iterable<Widget> get _renderWidget sync* {
    yield AgoraRenderWidget(0, local: true, preview: false);

    for (final uid in _remoteUsers) {
      yield AgoraRenderWidget(uid);
    }
  }

  VideoSession _getVideoSession(int uid) {
    return _sessions.firstWhere((session) {
      return session.uid == uid;
    });
  }

  List<Widget> _getRenderViews() {
    return _sessions.map((session) => session.view).toList();
  }

  static TextStyle textStyle = TextStyle(fontSize: 18, color: Colors.blue);

  Widget _buildInfoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemExtent: 24,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text(_infoStrings[i]),
        );
      },
      itemCount: _infoStrings.length,
    );
  }
}

class VideoSession {
  int uid;
  Widget view;
  int viewId;

  VideoSession(int uid, Widget view) {
    this.uid = uid;
    this.view = view;
  }
}
