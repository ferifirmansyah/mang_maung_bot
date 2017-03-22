import {ErrorHandlingService} from '../../services/error-handling.service';
import {Logging, insertAudit} from '../../services/logging.service';
import {DataAccessService} from '../../services/data-access.service';
import {vEnv,config} from '../../main';
import {TokenModel} from '../../model/token.model';
import {Token} from '../../services/token.service';
import {S3UploadService} from '../../services/s3.upload.service';
declare var require: any;
var vMode = require('../../config/mode.json')['mode'];
var vConfig = require('../../config/config.json')[vMode];

interface uploadData{
    pFName:string,
    pFDesc:string, // file description provided by frontend
    pFType:string,
    pFPath:string,
    pCId:string, // categoryid provided by frontend
    pUName:string
}
interface editFile extends uploadData{
    pFId:string
}

interface loginData{
    userid:string;
    password:string;
}

var fs = require('fs');
interface categoryData{
    cat_id:string;
    cat_name:string;
    cat_desc:string;
    cat_type:string;
    cat_parent:string;
    by:string;
}
export interface AdminControllerInterface {
    login(pRequest: any, pResponse: any): Promise<void>;
    upload(pRequest: any, pResponse: any): Promise<void>;
    categoryAdd(pRequest: any, pResponse: any): Promise<void>;
    categoryUpdate(pRequest: any, pResponse: any): Promise<void>;
    categoryDelete(pRequest: any, pResponse: any): Promise<void>;
}
export class AdminController implements AdminControllerInterface {
    constructor() {
        Logging('initialize admin controller');
    }

    async login(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling login function');
        try {
            let vParam:loginData = pRequest.body;
            let vResult:any;
            let vToken: TokenModel;
            if (vParam.userid == undefined || vParam.userid == null || vParam.userid == "" ||
               vParam.password == undefined || vParam.password == null || vParam.password == "") {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 1001, 'Invalid Login Parameters');
                return;
            }
            vResult = await DataAccessService.executeSP('login', vParam, true);
            if(vResult === null){
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 1002, 'Invalid userid or password');
                return;
            }
            else{
                vResult = vResult[0];
                vToken = new TokenModel();
                vToken.setUserId(vResult.user_id);
                vToken.setFullname(vResult.fullname);
                Logging(`${vResult.user_id} login`);
                pResponse.header('accessToken', Token.encryptToken(vToken));
                pResponse.header('created', Date.now());
                insertAudit(vResult.user_id,'Login', vParam);
                pResponse.status(200).send("Successfully login");
            }
        }
        catch (err) {
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 1000, err);
        }
    }
    async changePassword(pRequest: any, pResponse: any){
        Logging('calling change password function');
        try{
            if(pRequest.body.userid==undefined||pRequest.body.oldpass==undefined||pRequest.body.newpass==undefined){
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 2001, 'Invalid Parameters');
                return;
            }
            var params = pRequest.body;
            let result = await DataAccessService.executeSP('changepass',params,true);
            pResponse.status(200).json(result);
        }
        catch(err){
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 2000, err);
        }
    }

    async upload(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling upload function');
        try {
            let vTokenObject: TokenModel = pResponse.locals.token;
            let vParam:uploadData = pRequest.body;
            let vResult = "";
            let s3:S3UploadService = new S3UploadService();
            let vTempName:string="";
            let storage = vConfig.storage;
            let byte:any;
            if (vParam.pFDesc == undefined || vParam.pFDesc == null || vParam.pFDesc == "" ||
               vParam.pCId == undefined || vParam.pCId == null || vParam.pCId == "") {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 2001, 'Invalid Parameters');
                return;
            }
            if (!pRequest.files.file1) {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 2002, 'No files were uploaded');
                return;
            }
            vParam.pFType = pRequest.files.file1.type;
            vParam.pFName = pRequest.files.file1.originalFilename;
            vParam.pFPath = pRequest.files.file1.path;
            vTempName= vParam.pFPath.substring(vParam.pFPath.indexOf(storage)+storage.length);
            byte = fs.readFileSync(vParam.pFPath);
            fs.unlinkSync(vParam.pFPath);
            vParam.pUName = vTokenObject.getFullname();
            vParam.pFPath = vTempName;
            vResult = await DataAccessService.executeSP('addfile', vParam, true);
            await s3.upload(vTempName,byte);
            insertAudit(vTokenObject.getUserId(),'Add New File', vParam); 
            pResponse.status(200).send("Successfully upload file");
        }
        catch (err) {
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 2000, err);
        }
    }

    async editFile(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling editFile function');
        try {
            let vTokenObject: TokenModel = pResponse.locals.token;
            let vParam:editFile = pRequest.body;
            let vResult:any;
            let s3:S3UploadService = new S3UploadService();
            let vTempName:string="";
            let storage:string = 'Storage\\';
            let byte:any;
            if (vParam.pFDesc == undefined || vParam.pFDesc == null || vParam.pFDesc == "" ||
               vParam.pFId == undefined || vParam.pFId == null || vParam.pFId == "") {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 2001, 'Invalid Parameters');
                return;
            }

            if(pRequest.files.file1!=undefined){
                vParam.pFType = pRequest.files.file1.type || "EXISTING";
                vParam.pFName = pRequest.files.file1.originalFilename || "EXISTING";
                vParam.pFPath = pRequest.files.file1.path || "EXISTING";
                vParam.pUName = vTokenObject.getFullname();
                if(vParam.pFName == 'EXISTING')
                    fs.unlinkSync(vParam.pFPath);
                else{
                    vTempName= vParam.pFPath.substring(vParam.pFPath.indexOf(storage)+storage.length);
                    byte = fs.readFileSync(vParam.pFPath);
                    fs.unlinkSync(vParam.pFPath);
                    vParam.pUName = vTokenObject.getFullname();
                    vParam.pFPath = vTempName;
                    await s3.upload(vTempName,byte);
                }
            }
            else{
                vParam.pFType = "";
            }
            vResult = await DataAccessService.executeSP('editfile', vParam, true);
            if(vParam.pFName != 'EXISTING')
                await s3.delete(vResult);
            Logging(`upload ${vParam.pFName} to server at ${vParam.pFPath}`);
            insertAudit(vTokenObject.getUserId(),'Edit File', vParam);    
            pResponse.status(200).send("Successfully edit file");
        }
        catch (err) {
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 2000, err.desc);
        }
    }
    
    async deleteFile(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling deleteFile function');
        try {
            let vTokenObject: TokenModel = pResponse.locals.token;
            let vParam:editFile = pRequest.body;
            let vResult = "";
            let s3:S3UploadService = new S3UploadService();
            let vTempName:string="";
            let storage = 'Storage\\';
            if (vParam.pFId == undefined || vParam.pFId == null || vParam.pFId == "") {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 2001, 'Invalid Parameters');
                return;
            }
            vResult = await DataAccessService.executeSP('deletefile', vParam, true);
            vTempName= vResult.substring(vResult.indexOf(storage)+storage.length);
            await s3.delete(vResult);
            if(vResult == null){
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 2003, 'File not found');
                return;
            }
            Logging(`Delete file (id) : ${vParam.pFId}`);
            insertAudit(vTokenObject.getUserId(),'Delete File', vParam);
            pResponse.status(200).send("Successfully delete file");
        }
        catch (err) {
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 2000, err);
        }
    }
    async categoryAdd(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling categoryAdd function');
        try {
            let vParam:categoryData = pRequest.body;
            
            let vTokenObject: TokenModel = pResponse.locals.token;
            vParam.by = vTokenObject.getUserId();
            Logging('category parameter: '+JSON.stringify(vParam,null,4));

            let vResult:any;
            if (vParam.cat_name == undefined || vParam.cat_name == null || vParam.cat_name == "" ||
                vParam.cat_type == undefined || vParam.cat_type == null || vParam.cat_type == "" ||
                vParam.cat_desc == undefined || vParam.cat_desc == null || vParam.cat_desc == "" ||
                vParam.cat_parent == undefined || vParam.cat_parent == null || vParam.cat_parent == "") {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 1001, 'Invalid category Parameters');
                return;
            }

            vResult = await DataAccessService.executeSP('category_add', vParam, true);
            if(vResult === null){
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 1002, 'new category couldn"t be added to database');
                return;
            }
            else
                pResponse.status(200).send("New category is successfully added to database");
                Logging('New category is successfully added to database');
                insertAudit(vTokenObject.getUserId(),'Add New Category', vParam);
        }
        catch (err) {
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 1000, err);
        }
    }
    async categoryUpdate(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling categoryUpdate function');
        try {
            let vParam:categoryData = pRequest.body;

            let vTokenObject: TokenModel = pResponse.locals.token;
            vParam.by = vTokenObject.getUserId();
            Logging('category parameter: '+JSON.stringify(vParam,null,4));

            let vResult:any;
            if (vParam.cat_id == undefined || vParam.cat_id == null || vParam.cat_id == "") {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 1001, 'Invalid category Parameters');
                return;
            }

            vResult = await DataAccessService.executeSP('category_update', vParam, true);
            if(vResult === null){
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 1002, 'this category='+vParam.cat_name+' couldn"t be updated');
                return;
            }
            else
                pResponse.status(200).send("this category="+vParam.cat_name+" was successfully updated");
                Logging("this category="+vParam.cat_name+" was successfully updated");
                insertAudit(vTokenObject.getUserId(),'Edit Category', vParam);
        }
        catch (err) {
            Logging(err);
            if (err.code)
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, err.code, err.desc);
            else
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 500, 1000, err);
        }
    }
    async categoryDelete(pRequest: any, pResponse: any): Promise<void> {
        Logging('calling categoryDelete function');
        try {
            let vParam:categoryData = pRequest.body;

            let vTokenObject: TokenModel = pResponse.locals.token;

            Logging('category parameter: '+JSON.stringify(vParam,null,4));

            let vResult:any;
            if (vParam.cat_id == undefined || vParam.cat_id == null || vParam.cat_id == "") {
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 1001, 'Invalid category Parameters');
                return;
            }

            vResult = await DataAccessService.executeSP('category_delete', vParam, true);
            if(vResult === null){
                ErrorHandlingService.throwHTTPErrorResponse(pResponse, 400, 1002, 'this category='+vParam.cat_id+' couldn"t be deleted');
                return;
            }
            else
                pResponse.status(200).send("this category="+vParam.cat_id+" was successfully deleted");
                Logging("this category="+vParam.cat_id+" was successfully deleted");
                insertAudit(vTokenObject.getUserId(),'Delete Category', vParam);
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