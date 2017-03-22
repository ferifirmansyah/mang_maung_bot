declare var require:any,process:any;
import {vEnv,config} from '../main';
import {Logging} from './logging.service';
var vAWS = require('aws-sdk');
var vRequest = require('request');
var vFS = require('fs');
// vAWS.config.accessKeyId = 'AKIAJ6KP6NNEVOBW7RQA';
// vAWS.config.secretAccessKey = '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';
vAWS.config.accessKeyId = 'AKIAJ66LQ6BL2VQPAGEQ';
vAWS.config.secretAccessKey = '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';

export class S3UploadService {
	constructor() {
	}

	getUploadedFile(pFileName: string, pPath: string) {
		let vUrl = 'https://' + config.upload.bucket + '.s3.amazonaws.com/' + config.upload.path + pPath + pFileName; 
		return vUrl;
	}
    upload(pFileName: string, pFile: any){
        return new Promise<any>(
			function(pResolve, pReject) {
                var s3bucket = new vAWS.S3({ params: { Bucket: config.upload.bucket } });
                var params = {
                    Key: pFileName,
                    Body: pFile,
                    ACL: 'public-read-write'
                };
                s3bucket.upload(params, function (err: any, data: any) {
                    if (err) {
                        Logging('ERROR MSG: '+err);
                        pReject(err);
                    } else {
                        Logging('Successfully uploaded data to AWS');
                        pResolve(true);
                    }
                }); 
        });
    }
	delete(pFileName: string){
        return new Promise<any>(
			function(pResolve, pReject) {
                var params = {
                    Key: pFileName, /* required */
                };
                var s3 = new vAWS.S3({ params: { Bucket: config.upload.bucket } });
                s3.deleteObject(params, function (err: any, data: any) {
                    if (err) {
                        Logging("error aws : "+err); // an error occurred
                        pReject(err);
                    }
                    else {
                        Logging(data);  // successful response 
                        pResolve(true);
                    }        
                });
        });
    }
}