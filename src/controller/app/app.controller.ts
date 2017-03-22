import {ErrorHandlingService} from '../../services/error-handling.service';
import {Logging,insertAudit} from '../../services/logging.service';
import {DataAccessService} from '../../services/data-access.service';
import {vEnv,config} from '../../main';
import {S3UploadService} from '../../services/s3.upload.service';
declare var require: any;

var fs = require('fs');

interface downloadData{
    filepath:string;
}
export interface AppControllerInterface {
    getCatAndFile(pRequest: any, pResponse: any): Promise<void>;
    download(pRequest: any, pResponse: any): Promise<void>;
}

export class AppController implements AppControllerInterface {
    constructor() {
        Logging('initialize app controller');
    }
    
    async download(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling download function');
        try {
            let vParam:downloadData = pRequest.query;
            Logging(JSON.stringify(pRequest.query));
            let filepath:string = vParam.filepath;
            let s3:S3UploadService = new S3UploadService();
            if (vParam.filepath == undefined || vParam.filepath == null || vParam.filepath == "") {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 2001, 'Invalid Parameters');
                return;
            }
            pResponse.status(200).send(s3.getUploadedFile(vParam.filepath,''));
        }
        catch (err) {
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 1000, err);
        }
    }
    async getCatAndFile(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling getCatAndFile function');
        try {
            Logging('query from category & file table');

            let listCatAndFile: any = await DataAccessService.executeSP('category_getlist',null); 
        
            Logging('sent to front');
            pResponse.status(200).json(listCatAndFile);
        }
        catch (err) {
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 1000, err);
        }
    }
}