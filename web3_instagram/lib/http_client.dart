import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PiniataApiClient {
//   Future<File> urlToFile(String imageUrl) async {
// // generate random number.
//     var rng = Random();
// // get temporary directory of device.
//     Directory tempDir = await getTemporaryDirectory();
// // get temporary path from temporary directory.
//     String tempPath = tempDir.path;
// // create a new file in temporary path with random file name.
//     File file = File(tempPath + (rng.nextInt(100)).toString() + '.png');
// // call http.get method and pass imageUrl into it to get response.
//     http.Response response = await http.get(Uri.parse(imageUrl));
// // write bodyBytes received in response to file.
//     await file.writeAsBytes(response.bodyBytes);
// // now return the file which is created with random name in
// // temporary directory and image bytes from response is written to // that file.
//     return file;
//   }

  static const url = "https://api.pinata.cloud/pinning/pinFileToIPFS";

  generateHash(String apiKey, String apiSecret) async {
    var instaUrl =
        'https://scontent.cdninstagram.com/v/t51.2885-15/27880476_215023845729293_561938703371468800_n.jpg?_nc_cat=111&ccb=1-5&_nc_sid=8ae9d6&_nc_ohc=EFFtjF5rpj0AX_XVw9G&_nc_ht=scontent.cdninstagram.com&edm=ANo9K5cEAAAA&oh=00_AT82pkcrXqGmO-co6YTaY46dzvqejIZQp7KbMYmJ5a3SBw&oe=61EDF3EA';
    var headers = <String, String>{
      "pinata_api_key": apiKey,
      "pinata_secret_api_key": apiSecret,
    };
    var testUrl = '27880476_215023845729293_561938703371468800_n.jpg';
    var instaUri = Uri.parse(instaUrl);
    // final file = await urlToFile(instaUrl);
    http.Response response = await http.get(
      instaUri,
    );
    Uint8List bytes = await http.readBytes(instaUri);

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
    ));
    request.headers.addAll(headers);

    http.StreamedResponse responsee = await request.send();

    if (response.statusCode == 200) {
      print(await responsee.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
  }
}
