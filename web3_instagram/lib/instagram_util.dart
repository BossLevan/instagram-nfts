import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// class InstagramMedia extends StatefulWidget {
//   final String? appID;
//   final String? appSecret;
//   final int? mediaTypes;
//   const InstagramMedia(
//       {Key? key,
//       @required this.appID,
//       @required this.appSecret,
//       @required this.mediaTypes})
//       : super(key: key);
//   /*
//   mediaTypes options:
//   0 - images only (No CAROUSEL_ALBUM)
//   1 - videos only (No CAROUSEL_ALBUM)
//   2 - images and videos (No CAROUSEL_ALBUM)
//   3 - everything - everything (CAROUSEL_ALBUM, VIDEO, IMAGE)
//   */

//   @override
//   _InstagramMediaState createState() => _InstagramMediaState();
// }

// class _InstagramMediaState extends State<InstagramMedia> {
//   final webViewPlugin = FlutterWebviewPlugin();
//   StreamSubscription<String> _onUrlChanged;
//   GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

//   String? accessToken;
//   String? accessCode;
//   String? igUserID;

//   int stage = 0;

//   @override
//   void initState() {
//     super.initState();
//     _onUrlChanged = webViewPlugin.onUrlChanged.listen((String url) {
//       if (mounted) {
//         if (url.contains("code=")) {
//           setState(() {
//             accessCode = (url.split("code=")[1]).replaceAll("#_", "");
//             stage = 1;
//           });
//           var map = <String, dynamic>{};
//           map['client_id'] = widget.appID;
//           map['client_secret'] = widget.appSecret;
//           map['grant_type'] = 'authorization_code';
//           map['redirect_uri'] = 'https://httpstat.us/200';
//           map['code'] = accessCode;
//           _getShortLivedToken(map);
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _onUrlChanged.cancel();
//     webViewPlugin.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     String urlOne =
//         "https://instagram.com/oauth/authorize/?client_id=${widget.appID}&redirect_uri=https://httpstat.us/200&&scope=user_profile,user_media&response_type=code&hl=en";

//     return Scaffold(
//         body: StreamBuilder(
//             stream: Stream.value(stage),
//             builder: (context, stageSnap) {
//               if (stageSnap.data == 0) {
//                 return WebviewScaffold(
//                   key: scaffoldKey,
//                   appBar: AppBar(
//                     title: Text('Instagram'),
//                     centerTitle: true,
//                   ),
//                   url: urlOne,
//                 );
//               } else if (stageSnap.data == 1) {
//                 return Container(
//                   color: Colors.transparent,
//                   width: MediaQuery.of(context).size.width,
//                   height: MediaQuery.of(context).size.height,
//                   child: Center(
//                     child: Text('Fetching Media...'),
//                   ),
//                 );
//               }
//               return Container(
//                 color: Colors.transparent,
//                 width: MediaQuery.of(context).size.width,
//                 height: MediaQuery.of(context).size.height,
//                 child: Center(
//                   child: Text('Fetching Media...'),
//                 ),
//               );
//             }));
//   }

//   _getShortLivedToken(map) async {
//     String urlTwo = 'https://api.instagram.com/oauth/access_token';
//     http.Response response = await http.post(urlTwo, body: map);
//     var respData = json.decode(response.body);
//     setState(() {
//       accessToken = respData['access_token'];
//       igUserID = (respData['user_id']).toString();
//     });
//     _getMedia(context);
//   }

//   _getMedia(context) async {
//     var mediaUrls = [];
//     var mediaTimestamps = [];
//     var mediaIDs = [];
//     var mediaTypes = [];
//     var mediaCaptions = [];
//     var respData;
//     String urlThree = 'https://graph.instagram.com/' +
//         igUserID +
//         '/media?access_token=' +
//         accessToken +
//         '&fields=timestamp,media_url,media_type,caption';
//     http.Response response = await http.get(urlThree);
//     respData = (json.decode(response.body))['data'];
//     for (var i = 0; i < respData.length; i++) {
//       if (widget.mediaTypes == 0 && (respData[i])['media_type'] == 'IMAGE') {
//         mediaUrls.add((respData[i])['media_url']);
//         mediaTimestamps.add((respData[i])['timestamp']);
//         mediaIDs.add((respData[i])['id']);
//         mediaTypes.add((respData[i])['media_type']);
//         mediaCaptions.add((respData[i])['caption']);
//       } else if (widget.mediaTypes == 1 &&
//           (respData[i])['media_type'] == 'VIDEO') {
//         mediaUrls.add((respData[i])['media_url']);
//         mediaTimestamps.add((respData[i])['timestamp']);
//         mediaIDs.add((respData[i])['id']);
//         mediaTypes.add((respData[i])['media_type']);
//         mediaCaptions.add((respData[i])['caption']);
//       } else if (widget.mediaTypes == 2 &&
//           ((respData[i])['media_type'] == 'VIDEO' ||
//               (respData[i])['media_type'] == 'IMAGE')) {
//         mediaUrls.add((respData[i])['media_url']);
//         mediaTimestamps.add((respData[i])['timestamp']);
//         mediaIDs.add((respData[i])['id']);
//         mediaTypes.add((respData[i])['media_type']);
//         mediaCaptions.add((respData[i])['caption']);
//       } else if (widget.mediaTypes == 3) {
//         mediaUrls.add((respData[i])['media_url']);
//         mediaTimestamps.add((respData[i])['timestamp']);
//         mediaIDs.add((respData[i])['id']);
//         mediaTypes.add((respData[i])['media_type']);
//         mediaCaptions.add((respData[i])['caption']);
//       }
//     }

//     var returnData = [
//       mediaUrls,
//       mediaTimestamps,
//       mediaIDs,
//       mediaTypes,
//       mediaCaptions
//     ];
//     Navigator.of(context).pop(returnData);
//   }
// }

class InstagramUtil {
  // final String? appID;
  // final String? appSecret;
  String? accessToken;
  String? get localAccessCode {
    _accessCodeLocal = accessCode;
    return _accessCodeLocal;
  }

  final String? accessCode;
  String? _accessCodeLocal;
  String? igUserID;
  final String _appSecret = 'c4184d43c30358047ce4a5464e0602e6';
  final String _appID = '466508148203801';
  InstagramUtil({
    @required this.accessCode,
  });

  Future<List<String>> getShortLivedToken() async {
    var map = <String, dynamic>{};
    map['client_id'] = _appID;
    map['client_secret'] = _appSecret;
    map['grant_type'] = 'authorization_code';
    map['redirect_uri'] = 'https://instamint.web.app/static.html';
    map['code'] = accessCode;
    String urlTwo = 'https://api.instagram.com/oauth/access_token';
    http.Response response = await http.post(Uri.parse(urlTwo), body: map);
    var respData = json.decode(response.body);

    accessToken = respData['access_token'];
    igUserID = (respData['user_id']);
    return [accessToken!, igUserID!];
  }

  String? getIgUserID() {
    return igUserID;
  }

  Future<List> getMedia(String accessToken, String userID) async {
    var mediaUrls = [];
    var mediaTimestamps = [];
    var mediaIDs = [];
    var mediaTypes = [];
    var mediaCaptions = [];
    // ignore: prefer_typing_uninitialized_variables
    var respData;

    String urlThree = 'https://graph.instagram.com/' +
        ('me/media?fields=id,caption&') +
        'access_token=' +
        accessToken +
        '&fields=timestamp,media_url,media_type,caption';
    http.Response response = await http.get(Uri.parse(urlThree));
    respData = (json.decode(response.body))['data'];

    for (var i = 0; i < respData.length; i++) {
      mediaUrls.add((respData[i])['media_url']);
      mediaTimestamps.add((respData[i])['timestamp']);
      mediaIDs.add((respData[i])['id']);
      mediaTypes.add((respData[i])['media_type']);
      mediaCaptions.add((respData[i])['caption']);
    }

    var returnData = [
      mediaUrls,
      mediaTimestamps,
      mediaIDs,
      mediaTypes,
      mediaCaptions
    ];
    return returnData;
  }
}
