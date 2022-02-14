import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class ShowTimeModel extends ChangeNotifier {
  bool isLoading = true;

  final String _rpcUrl = "http://127.0.0.1:7545";
  final String _wsUrl = "ws://127.0.0.1:7545/";

  final String _privateKey =
      "edbc4feab020989ee5cae35f4d414edcfc5e951cb2ad7a83de7f6f853cfd1f1d";

  Web3Client? _client;
  String? _abiCode;

  Credentials? _credentials;
  EthereumAddress? _contractAddress;
  EthereumAddress? _ownAddress;
  DeployedContract? _contract;

  ContractFunction? _issueToken;
  ContractFunction? _issueTokenBatch;
  ContractFunction? _setBaseUri;
  ContractFunction? _uri;

  ShowTimeModel() {
    init();
  }

  Future<void> init() async {
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    String abiStringFile = await rootBundle
        .loadString("contractss/build/contracts/ShowtimeMT.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    notifyListeners();
  }

  Future<void> getCredentials() async {
    _credentials = EthPrivateKey.fromHex(_privateKey);
    // print('1st credentials: ${_credentials..toString()}');
    _ownAddress = await _credentials?.extractAddress();
    notifyListeners();
  }

  Future<void> getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode!, "ShowTimeMT"), _contractAddress!);
    _issueToken = _contract?.function("issueToken");
    _issueTokenBatch = _contract?.function("issueTokenBatch");
    _uri = _contract?.function("uri");

    // await getTodos();
    notifyListeners();
  }

  void mintToken() async {
    print('credentials: ${_credentials.toString()}');
    await _client?.sendTransaction(
        _credentials!,
        Transaction.callContract(
            contract: _contract!,
            function: _issueToken!,
            parameters: [
              _ownAddress,
              BigInt.from(1),
              'QmTp2hEo8eXRp6wg7jXv1BLCMh5a4F3B7buAUZNZUu772j',
              Uint8List.fromList(utf8.encode('input')),
              _ownAddress,
              BigInt.from(0)
            ]));
  }
}
