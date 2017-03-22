import {ErrorHandlingService} from './error-handling.service';
import {SequelizeService} from './sequelize.service';
import {Utility} from '../shared/utility';
import {Logging} from './logging.service';

export class DataAccessService{

	constructor() {
        Logging('Initialize data access service');
	}

	public static executeSP(pSPName:string, pParams: any, pIsJSONFormat?: boolean): Promise<string> {
        Logging('Executing sp : '+pSPName);
		return new Promise<string>(
			function(pResolve, pReject) {
				try{
					// build stored procedure params
					let vParams:string;
					// if we pass a JSON as parameter
					// make sure that the created stored procedure accept 1 param with type of JSON
					if(pIsJSONFormat) {
						vParams = '(\''+JSON.stringify(pParams)+'\')';
					}else {
						// default params for stored procedure if null object is passed as parameter
						// converting params object into parameter in stored procedure
						if(pParams) {
							vParams = '(';
							for(let vParam in pParams){
								if(pParams[vParam] !== undefined && pParams[vParam] !== null && typeof pParams[vParam] === 'string' && pParams[vParam].indexOf('\'') !== -1) {
									pParams[vParam] = Utility.replaceAll(pParams[vParam],'\'','\'\'');
								}
								vParams += "'" + pParams[vParam] + "',";
							}
							vParams = vParams.substring(0,vParams.lastIndexOf(',')) + ');';
						}
						else{
							vParams = '();';
						}
					}
					// build query to execute stored procedure
					let vSQL = 'SELECT ' + pSPName + vParams;
					// console.log(vSQL);
					SequelizeService.sequelize.query(vSQL, { type: SequelizeService.sequelize.QueryTypes.SELECT }).then(function(pResult:any){
						// stored procedure will return 0 if there is no errors
						let vResult = pResult[0][pSPName.toLowerCase()];
						if(vResult.status === 0) {
							Logging("success : ");
							Logging(vResult.result);
							pResolve(vResult.result);
						// functional error occured while execute the stored procedure
						}else {
							Logging('Error while executing query : ' + vSQL);
							Logging('Result : ' + JSON.stringify(vResult));
							ErrorHandlingService.throwPromiseError(pReject,vResult.error_code,vResult.error_msg);
						}
					}).catch(function(pErr:any){
						Logging('Error while executing query : ' + vSQL);
						// throwing error from the sequelize
						Logging('Error ' + pErr);
						ErrorHandlingService.throwPromiseError(pReject,400, pErr);
					});
				}catch(pErr) {
					ErrorHandlingService.throwPromiseError(pReject, 400,pErr);
				}
			}
		);
	}
}