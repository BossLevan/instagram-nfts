class IPFSmodel {
  String? ipfsHash;
  int? pinSize;
  String? timeStamp;
  bool? isDuplicate;

  IPFSmodel({this.ipfsHash, this.isDuplicate, this.pinSize, this.timeStamp});

  factory IPFSmodel.fromJson(Map<String, dynamic> json) {
    return IPFSmodel(
      ipfsHash: json["IpfsHash"] as String,
      pinSize: json["PinSize"] as int,
      timeStamp: json["Timestamp"] as String,
      isDuplicate: json["isDuplicate"] as bool,
    );
  }
}
