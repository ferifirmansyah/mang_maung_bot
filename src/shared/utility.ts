export module Utility {
	export function replaceAll(pString:string, pSearch:string, pReplacement:string) {
		return pString.replace(new RegExp(pSearch, 'g'), pReplacement);
	};
	
	export function sortJSON(pJSONObject: any, pSortKey: string, pASC?: boolean) {
		let vAsc: boolean = pASC ? true : false;
		return pJSONObject.sort(function(a:any,b:any){
			if(typeof a[pSortKey] === 'number') {
				return vAsc ? a[pSortKey] - b[pSortKey] : b[pSortKey] - a[pSortKey];
			}
			else if (typeof a[pSortKey] === 'string') {
				if (vAsc) {
					return (a[pSortKey] > b[pSortKey]) ? 1 : ((a[pSortKey] < b[pSortKey]) ? -1 : 0);
				}
				else {
					return (b[pSortKey] > a[pSortKey]) ? 1 : ((b[pSortKey] < a[pSortKey]) ? -1 : 0);
				}
			}
		});
	}
	export function excludeJSON(obj:any,type:any,filter:any){
		var vData = obj;
		for(let i = 0;i<vData.length;i++){
			if(vData[i][type] == filter){
				vData.splice(i,1);
				i-=1;
			}
		}
		return vData;
	}
	export function findJSON(obj:any,type:any,filter:any){
		var temp:any = [];
		for(var data in obj){
			if(obj[data][type] == filter)
				temp.push(obj[data]);
		}
		return temp;
	}
	
	export function cloneObject(obj:any) {
		if (obj === null || typeof obj !== 'object') {
			return obj;
		}
	
		var temp = obj.constructor(); // give temp the original obj's constructor
		for (var key in obj) {
			temp[key] = cloneObject(obj[key]);
		}
		return temp;
	}
}