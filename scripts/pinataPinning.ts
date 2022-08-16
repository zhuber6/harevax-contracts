var axios = require('axios');
var fs = require('fs');
import {resolve, basename} from "path";
const rfs = require("recursive-fs");
import FormData from "form-data";
const JWT = process.env.PINATA_JWT;

const PIN_FILE_URL = `https://api.pinata.cloud/pinning/pinFileToIPFS`;
const PIN_JSON_URL = `https://api.pinata.cloud/pinning/pinJSONToIPFS`;

export async function pinDirectoryToPinata(path: string) {

  try {
    const { dirs, files } = await rfs.read(path);
    let data = new FormData();
    for (const file of files) {
      data.append(`file`, fs.createReadStream(file),
      {filepath: "sneakers/" + basename(file)});
    }

    var config = {
      method: 'post',
      url: PIN_FILE_URL,
      headers: { 
        "Content-Type": `multipart/form-data;`,
        "Authorization": "Bearer " + JWT,
      },
      data : data
    };

    const res = await axios(config);

    // console.log(res.data);
  } catch (error) {
    console.log(error);
  }
};

export async function pinFileToPinata(path: string) {
  try {
    let data = new FormData();
    data.append(`file`, fs.createReadStream(path));

    var config = {
      method: 'post',
      url: PIN_FILE_URL,
      headers: {
        "Authorization": "Bearer " + JWT,
      },
      data : data
    };

    const res = await axios(config);

    // console.log(res.data);
  } catch (error) {
    console.log(error);
  }
};

export async function pinJsonToPinata(json: string) {
  try {
    var config = {
      method: 'post',
      url: PIN_JSON_URL,
      headers: {
        'Content-Type': 'application/json', 
        "Authorization": "Bearer " + JWT,
      },
      data : json
    };

    const res = await axios(config);

    // console.log(res.data.IpfsHash);
    return res.data.IpfsHash;
  } catch (error) {
    console.log(error);
  }
};