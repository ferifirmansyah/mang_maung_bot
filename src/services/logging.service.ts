import {DataAccessService} from './data-access.service';
import {vEnv,config} from '../main';
declare var require:any;
const enableLogging = config['debug'];
var ErrorConfig = require('../config/error.json');
var fs = require('fs');
var moment = require('moment');
export function Logging(msg:any) {
    if (enableLogging) {
        var time = moment().format('DD-MMM-YYYY, hh:mm:ss a');
        console.log(`${time} | ${Object.prototype.toString.call(msg) == "[object Object]" ||
        Object.prototype.toString.call(msg) == "[object Array]" ? JSON.stringify(msg) : msg }`);
    }
}

export function insertAudit(userId:string, action:string,details:any){
    if(getType(details)=='array'||getType(details)=='object'){
        details = JSON.stringify(details,null,4);
    }
    let vParam = {
        user_id:userId,
        action:action,
        details:details
    }
    let vPayload = DataAccessService.executeSP('audit_add',vParam,true);
}

function getType(p:any) {
    if (Array.isArray(p)) return 'array';
    else if (typeof p == 'string') return 'string';
    else if (p != null && typeof p == 'object') return 'object';
    else return 'other';
}