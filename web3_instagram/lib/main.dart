import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:provider/provider.dart' as provider;
import 'package:web3_instagram/http_client.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:web3_instagram/instagram_util.dart';
import 'package:web3_instagram/showtime_model.dart';
import 'package:web3_instagram/ipfs_model.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
      theme: ThemeData(fontFamily: 'Euclid Circular A'), home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool? isConnectedToMetamask = false;
  String? _token = '';
  String? accessToken;
  String? userID;
  final client = PiniataApiClient();
  String? tokenId = '';

  html.WindowBase? _popupWin;
  String? _iPFShash = '';
  String? iGUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
  }

  Future _getAccessToken() async {
    final _access =
        await InstagramUtil(accessCode: _token).getShortLivedToken();
    accessToken = _access[0];
    userID = _access[1];
    print("gotten access token");
  }

  Future _getUserMedia() async {
    await _getAccessToken();
    final _media =
        await InstagramUtil(accessCode: _token).getMedia(accessToken!, userID!);
    iGUrl = _media[0][0];
    return [_media[0], _media[4]];
  }

  Future callFunction(String url, String name, String description) async {
    //Call of the IPFS function
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'pinFileToIPFS',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 5)));
    try {
      final HttpsCallableResult result = await callable.call(
        <String, String>{
          'message': url,
          'name': name,
          'description': description
        },
      );
      _iPFShash = IPFSmodel.fromJson(result.data).ipfsHash;
      return _iPFShash;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('caught firebase functions exception');
      debugPrint(e.code);
      debugPrint(e.message);
      debugPrint(e.details);
    } catch (e) {
      debugPrint('caught generic exception');
      debugPrint(e.toString());
    }
  }

  void _login(String data) {
    /// Parse data to extract the token.
    final receivedUri = Uri.parse(data);

    /// Close the popup window
    if (_popupWin != null) {
      _popupWin?.close();
      _popupWin = null;
    }

    setState(() => _token = receivedUri.queryParameters["code"]);
  }

  void connectToEthereum() async {
    if (ethereum != null) {
      try {
        // Prompt user to connect to the provider, i.e. confirm the connection modal
        final accs = await ethereum!
            .requestAccount(); // Get all accounts in node disposal
        accs; // [foo,bar]
        setState(() {
          isConnectedToMetamask = true;
        });
        debugPrint("successfully connected Metamask");
      } on EthereumUserRejected {
        debugPrint('User rejected the modal');
      }
    }
  }

  Future<TransactionResponse> mintFuckingNFTS(String ipfsHash) async {
    final web3provider = Web3Provider(ethereum!);
    final signer = web3provider.getSigner();
    String abiStringFile = await rootBundle.loadString("lib/abi.json");
    var jsonAbi = jsonDecode(abiStringFile);
    final _abiCode = jsonEncode(jsonAbi);
    final jsonInterface = Interface(_abiCode);

    final _ownAddress = await signer.getAddress();

    //Showtime contract Address
    const contractAddress = '0x8A13628dD5D600Ca1E8bF9DBc685B735f615Cb90';
    //Contract Object
    final contract = Contract(
      contractAddress,
      jsonInterface,
      web3provider.getSigner(),
    );

    //Mint the NFT
    final tx = await contract.send('issueToken', [
      _ownAddress,
      BigInt.from(1),
      ipfsHash,
      Uint8List.fromList(utf8.encode('0x00ffcd'))[0],
      _ownAddress,
      BigInt.from(0)
    ]);
    return tx;
    // final receipt = await tx.wait();

    // String firstHalf =
    //     "0x000000000000000000000000000000000000000000000000000000000000";
    // String secondHalf =
    //     "000000000000000000000000000000000000000000000000000000000000000";
    // String hex = receipt.logs[0].data;
    // var hexx = hex.split(firstHalf)[1].split(secondHalf)[0];
    // int tokenID = int.parse(hexx, radix: 16);
    // if (tokenID.toString().length < 4 && !tokenID.toString().endsWith("0")) {
    //   tokenID = int.parse(tokenID.toString() + "0");
    // }
    // return tokenID.toString();
  }

  Future<String> getNFTResponse(TransactionResponse tx) async {
    final receipt = await tx.wait();

    String firstHalf =
        "0x000000000000000000000000000000000000000000000000000000000000";
    String secondHalf =
        "000000000000000000000000000000000000000000000000000000000000000";
    String hex = receipt.logs[0].data;
    var hexx = hex.split(firstHalf)[1].split(secondHalf)[0];
    int tokenID = int.parse(hexx, radix: 16);
    if (tokenID.toString().length < 4 && !tokenID.toString().endsWith("0")) {
      tokenID = int.parse(tokenID.toString() + "0");
    }
    return tokenID.toString();
  }

  void _openPage() async {
    // /// Listen to message send with `postMessage`.
    html.window.onMessage.listen((event) {
      /// The event contains the token which means the user is connected.
      if (event.data.toString().contains('code=')) {
        _login(event.data);
      }
    });

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      final currentUri = Uri.base;
      final redirectUri = Uri(
        host: currentUri.host,
        scheme: currentUri.scheme,
        port: currentUri.port,
        path: '/static.html',
      );
      final authUrl =
          'https://api.instagram.com/oauth/authorize?client_id=466508148203801&redirect_uri=$redirectUri&scope=user_profile,user_media&response_type=code';
      _popupWin = html.window.open(authUrl, "Connect your Instagram",
          "width=800, height=900, scrollbars=yes");
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // String? intCode = code;
    return Scaffold(
        body: BodyWidget(
      screenSize: screenSize,
      tabController: _tabController,
      functions: [
        _openPage,
        _getAccessToken,
        _getUserMedia,
        connectToEthereum,
        mintFuckingNFTS,
        getNFTResponse,
        callFunction
      ],
      igUrl: iGUrl,
      token: _token,
      isConnected: isConnectedToMetamask!,
    ));
  }
}

class BodyWidget extends StatefulWidget {
  final screenSize;
  final TabController? tabController;
  final List? functions;
  final String? igUrl;
  final String? token;
  final bool? isConnected;

  BodyWidget(
      {this.functions,
      this.igUrl,
      this.isConnected,
      this.screenSize,
      this.tabController,
      this.token,
      Key? key})
      : super(key: key);

  @override
  State<BodyWidget> createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  String? tokenId = '';
  bool? isTokenIdRetrieved = false;
  TransactionResponse? tx;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      //Top Container
      Container(
        padding: const EdgeInsets.all(24),
        height: widget.screenSize.height * 0.45,
        width: widget.screenSize.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF434343), Colors.black87],
            stops: [0.0, 1.0],
            begin: FractionalOffset.centerLeft,
            end: FractionalOffset.centerRight,
            tileMode: TileMode.repeated,
          ),
          image: DecorationImage(
              image: AssetImage("images/background.png"), fit: BoxFit.none),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Instamint",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color(0xFF2E2B2B))),
                  onPressed: widget.isConnected == false
                      ? () => {
                            widget.functions![3](),
                          }
                      : () => DoNothingAction(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.isConnected == false
                          ? 'Connect Wallet'
                          : "Connected",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 30),
            const Text('Convert your Instagram Posts to NFTs⚡️',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 365),
              child: Text(
                'Mint your Instagram posts as NFTs and list them on your favourite marketplace! Connect your Instagram account below to get started!',
                style: TextStyle(
                  color: Colors.white54,
                  height: 1.4,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
      IgnorePointer(
        child: TabBar(
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey[400],
            labelStyle: const TextStyle(
              color: Color(0xFF4E4E4E),
              fontFamily: 'Euclid Circular A',
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            controller: widget.tabController!,
            tabs: const [
              Tab(text: "1. Connect your Instagram"),
              Tab(text: "2. Select Photos"),
              Tab(text: "3. View NFTs"),
            ]),
      ),
      const SizedBox(
        height: 40,
      ),
      Expanded(
        child: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          controller: widget.tabController!,
          children: [
            FirstTab(
                function: widget.functions![0],
                controller: widget.tabController!),
            SecondTab(
              getMedia: widget.functions![2],
              token: widget.token,
              mintNFTs: widget.functions![4],
              tokenID: tokenId!,
              getHash: widget.functions![6],
              refreshCallback: (TransactionResponse result) {
                setState(() {
                  tx = result;
                  isTokenIdRetrieved = true;
                });
              },
              tabController: widget.tabController,
            ),
            ThirdTab(
              tx: tx,
              tokenId: tokenId,
              getNFTResponse: widget.functions![5],
            ),
          ],
        ),
      ),
    ]);
  }
}

class ThirdTab extends StatefulWidget {
  final TransactionResponse? tx;
  final getNFTResponse;
  const ThirdTab({
    this.tx,
    this.getNFTResponse,
    Key? key,
    required this.tokenId,
  }) : super(key: key);

  final String? tokenId;

  @override
  State<ThirdTab> createState() => _ThirdTabState();
}

class _ThirdTabState extends State<ThirdTab> {
  String? _tokenId;
  void _openShowtime() async {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      final url =
          'https://showtime.io/t/polygon/0x8a13628dd5d600ca1e8bf9dbc685b735f615cb90/$_tokenId';
      html.window
          .open(url, 'Showtime', "width=800, height=900, scrollbars=yes");
    });
  }

  void _openOpenSea() async {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      final url =
          'https://opensea.io/assets/matic/0x8A13628dD5D600Ca1E8bF9DBc685B735f615Cb90/$_tokenId';
      html.window.open(url, 'Opensea', "width=800, height=900, scrollbars=yes");
    });
  }

  var future;
  @override
  void initState() {
    super.initState();
    setState(() {
      future = widget.getNFTResponse!(widget.tx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              children: const [
                SizedBox(
                  height: 40,
                ),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: Center(
                    child: SpinKitRotatingCircle(
                      color: Colors.black,
                      size: 50.0,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                ),
                Text(
                  "Hang on while we mint your NFT 😇 ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                    color: Color(0xFF4E4E4E),
                    fontFamily: 'Euclid Circular A',
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error. Please reload the page.'));
          } else if (snapshot.hasData) {
            _tokenId = snapshot.data!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "🎉",
                  style: TextStyle(fontSize: 30),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Congratulations!",
                  style: TextStyle(
                    color: Color(0xFF4E4E4E),
                    fontFamily: 'Euclid Circular A',
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 300.0),
                  child: Text(
                    // snapshot.data!,
                    "You have successfully minted your Instagram photos as NFTs. View them below",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.5,
                      color: Color(0xFF4E4E4E),
                      fontFamily: 'Euclid Circular A',
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                            ),
                            padding:
                                MaterialStateProperty.all<EdgeInsetsGeometry>(
                                    const EdgeInsets.all(20)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                const Color(0xFFEDEDED))),
                        onPressed: () => _openOpenSea(),
                        icon: const Icon(
                          Icons.north_east,
                          color: Colors.black54,
                          size: 20,
                        ),
                        label: const Text(
                          'View on Opensea',
                          style: TextStyle(
                              color: Color(0xFF6B6B6B),
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      TextButton.icon(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                            ),
                            padding:
                                MaterialStateProperty.all<EdgeInsetsGeometry>(
                                    const EdgeInsets.all(20)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                const Color(0xFFEDEDED))),
                        onPressed: () => _openShowtime(),
                        icon: const Icon(
                          Icons.north_east,
                          color: Colors.black54,
                          size: 20,
                        ),
                        label: const Text(
                          'View on Showtime',
                          style: TextStyle(
                              color: Color(0xFF6B6B6B),
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            );
          } else {
            return const Text('Empty data');
          }
        } else {
          return Text('State: ${snapshot.connectionState}');
        }
      },
    );
  }
}

class SecondTab extends StatefulWidget {
  final Function(TransactionResponse result)? refreshCallback;
  final mintNFTs;
  final getMedia;
  final getHash;

  final String? token;
  final TabController? tabController;
  String tokenID;

  SecondTab({
    this.tabController,
    this.refreshCallback,
    this.getHash,
    required this.tokenID,
    this.mintNFTs,
    this.token,
    this.getMedia,
    Key? key,
  }) : super(key: key);

  @override
  State<SecondTab> createState() => _SecondTabState();
}

class _SecondTabState extends State<SecondTab> {
  // ignore: prefer_typing_uninitialized_variables
  var future;
  bool isMintingNFT = false;
  int selectedIndex = 0;
  String? url;

  @override
  void initState() {
    super.initState();
    future = widget.getMedia!();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 50,
            width: 50,
            child: Center(
              child: SpinKitRotatingCircle(
                color: Colors.black,
                size: 50.0,
              ),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error. Please reload the page.'));
          } else if (snapshot.hasData) {
            url = snapshot.data![0][selectedIndex];
            return Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data?[0].length,
                    itemBuilder: (_, index) => Container(
                      margin: const EdgeInsets.only(left: 20),
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(BorderSide(
                              color: selectedIndex == index
                                  ? Colors.black26
                                  : Colors.white,
                              width: 3.0,
                            )),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(16)),
                          ),
                          height: 400,
                          width: 240,
                          child: Image(
                              image: Image.network(snapshot.data![0][index])
                                  .image),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                TextButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                      ),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(20)),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color(0xFF2E2B2B))),
                  //mint NFT
                  onPressed: () async {
                    final hash = await widget.getHash!(
                      snapshot.data?[0][selectedIndex],
                      "Instamint",
                      snapshot.data?[1][selectedIndex],
                    );
                    TransactionResponse tx = await widget.mintNFTs!(hash);
                    widget.refreshCallback!(tx);
                    await Future.delayed(const Duration(milliseconds: 200));
                    widget.tabController?.animateTo(2);
                  },

                  child: const Text(
                    'Confirm & Mint',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                )
              ],
            );
          } else {
            return const Text('Empty data');
          }
        } else {
          return Text('State: ${snapshot.connectionState}');
        }
      },
    );
  }
}

class FirstTab extends StatelessWidget {
  final Function? function;
  final TabController? controller;
  const FirstTab({
    this.controller,
    this.function,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 40,
        ),
        const SizedBox(
          height: 50,
          width: 50,
          child: Image(
              image: NetworkImage(
                  "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/800px-Instagram_logo_2016.svg.png")),
        ),
        const SizedBox(height: 20),
        const Text(
          "Connect your Instagram",
          style: TextStyle(
            color: Color(0xFF4E4E4E),
            fontFamily: 'Euclid Circular A',
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 300.0),
          child: Text(
            "Connect your Instagram account to import your pictures from Instagram. Instamint will NOT share or store your data ",
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.5,
              color: Color(0xFF4E4E4E),
              fontFamily: 'Euclid Circular A',
              fontWeight: FontWeight.w400,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(
          height: 40,
        ),
        TextButton.icon(
          style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                  const EdgeInsets.all(20)),
              backgroundColor:
                  MaterialStateProperty.all<Color>(const Color(0xFF2E2B2B))),
          //connect to instagram function
          onPressed: () async {
            function!();
            await Future.delayed(const Duration(milliseconds: 100));
            controller?.animateTo(1);
          },
          icon: const Icon(
            Icons.north_east,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            'Connect',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        )
      ],
    );
  }
}
