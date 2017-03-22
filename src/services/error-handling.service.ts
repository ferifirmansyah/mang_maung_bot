import {vEnv,config} from '../main';
declare var require:any;
var ErrorConfig = require('../config/error.json');

export class ErrorHandlingService {

	public static buildErrorObject(errorCode: number, errorDescription: string, inputError?: any): Object{
		// build error object
		// get error message in the config file if error description exists
		// if not, just use the passed errorDescription parameter
		if(ErrorConfig[errorCode]){
			errorDescription = ErrorConfig[errorCode];
		}
		let Error = {
			code: errorCode,
			desc: errorDescription,
			inputError : inputError
		};
		// if input errors (errors generated from class validator that is used in model) is passed
		if(!inputError) {
			delete Error.inputError;
		}
		return Error;
	}

	public static throwPromiseError(RejectFunction: Function, errorCode: number, errorDescription: string, inputError?: any) {
		RejectFunction(ErrorHandlingService.buildErrorObject(errorCode, errorDescription, inputError));
	}

	 public static throwError(errorCode: number, errorDescription: string, inputError?: any): Object {
		throw ErrorHandlingService.buildErrorObject(errorCode, errorDescription, inputError);
	}

	 public static throwHTTPErrorResponse(HTTPResponseObject: any, HTTPResponseStatus: number, errorCode: number, errorDescription: string, inputError?: any): void {
		/**************************************************/
		/* HTTPResponseStatus Possible value :            */
		/* 	 -- 400: System Error / Technical Error       */
		/*   -- 500: Non System Error / Functional Error  */
		/**************************************************/
		HTTPResponseObject.status(HTTPResponseStatus).json(ErrorHandlingService.buildErrorObject(errorCode, errorDescription, inputError));
	}
	public static throwHTTPErrorResponseNoEncrypt(HTTPResponseObject: any, HTTPResponseStatus: number, errorCode: number, errorDescription: string, inputError?: any): void {
		/**************************************************/
		/* HTTPResponseStatus Possible value :            */
		/* 	 -- 400: System Error / Technical Error       */
		/*   -- 500: Non System Error / Functional Error  */
		/**************************************************/
		if(config.encryption)
			HTTPResponseObject.status(HTTPResponseStatus).oldJson(ErrorHandlingService.buildErrorObject(errorCode, errorDescription, inputError));
		else
			HTTPResponseObject.status(HTTPResponseStatus).json(ErrorHandlingService.buildErrorObject(errorCode, errorDescription, inputError));
	}
}