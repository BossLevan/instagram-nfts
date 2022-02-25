const got = require("got");
const axios = require("axios");
const functions = require("firebase-functions");
const pinataSDK = require("@pinata/sdk");

exports.pinFileToIPFS = functions.region('europe-west2').https.onCall((data, context) => {
  // response.set({
  //       'Access-Control-Allow-Origin': '*',
  //       'Access-Control-Allow-Methods': 'GET,PUT,POST,DELETE,PATCH,OPTIONS',
  //       'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept, Authorization',
  //   });
  //   if (request.method == "OPTIONS") {
  //       response.sendStatus(200);
  //       return;
  //   }
  const postUrl = data.message;
  const postName = data.name;
  const description = data.description;
  const pinataApiKey = "63f52af2a6741e8d2f48";
  const pinataSecretApiKey = "03449f30ac630ecd3da2af02d" +
  "dfca3a3bbc20044c10175f0dd2ce6f96d356da8";
  const pinata = pinataSDK(pinataApiKey, pinataSecretApiKey);

  return axios({
    method: "get",
    url: postUrl,
    responseType: "stream",
  }).then(function(response) {
    console.log("fetching");
    return pinata.pinFileToIPFS(got.stream(postUrl).
        pipe(response.data)).then((result) => {
      let hash = result.IpfsHash;
      
      //send the metadata
      let metadata = {
        "description": description, 
        "image":`ipfs://${hash}`, 
        "name": postName,
      }

       return pinata.pinJSONToIPFS(metadata).then((result) => {
            //handle results here
            return result;
            }).catch((err) => {
                //handle error here
                console.log(err);
            });
    }).catch((err) => {
      // handle error here
      console.log(err);
    });
  });
});


