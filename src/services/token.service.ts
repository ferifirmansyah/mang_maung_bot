import {TokenModel} from '../model/token.model';
import {ErrorHandlingService} from './error-handling.service';
import {Logging} from './logging.service'
import {DataAccessService} from './data-access.service';
import {vEnv,config} from '../main';
declare var require:any;
var vNJwt = require('njwt');
var CryptoJS = require('crypto-js');


export class Token  {
	static vTimeout = 60 * 60 * 1000;//60 minutes
	constructor(){
			Logging('initialize token service');
	}
	static encryptToken(pObject: TokenModel): string{
		try{
			// load sign in key from config files
			let vSigningkey = config.token.key;
			// encrypt token
			let vJwt = vNJwt.create(pObject,vSigningkey);
			// set expiration for token
			vJwt.setExpiration();
			//vJwt.setExpiration(new Date().getTime() + this.vTimeout);
			let vToken = vJwt.compact();
			return vToken;
		}catch(pErr) {
			ErrorHandlingService.throwError(300, pErr.toString());
		}
	}
	static decryptToken(pToken:string): TokenModel{
		try{
			// load sign in key from config files
			let vSigningkey = config.token.key;
			let vVerifiedJwt = vNJwt.verify(pToken,vSigningkey).body;
			let vTokenObject = new TokenModel();
			vTokenObject.setUserId(vVerifiedJwt.userId);
            vTokenObject.setFullname(vVerifiedJwt.fullname);
			return vTokenObject;
		}catch(pErr){
			ErrorHandlingService.throwError(300, 'Invalid Access Token');
		}
	}
	
	async verifyToken(pRequest:any,pResponse:any,next:any){
		if(pRequest.method == 'OPTIONS') next();
		try{
			let vToken = pRequest.get('authorization').replace('Bearer ','');
			let vTokenObject: TokenModel = Token.decryptToken(vToken);
			pResponse.locals.token = vTokenObject;
			// renew the accessToken every time user hit API
			let vNewAccessToken = Token.encryptToken(vTokenObject);
			pResponse.header('accessToken', vNewAccessToken);
			pResponse.header('created', Date.now());
			next();
		}catch(ex){
			ErrorHandlingService.throwHTTPErrorResponse(pResponse,403,300, 'Invalid Access Token');
		}
	}
}