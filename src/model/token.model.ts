export class TokenModel{
    private userId: string;
    private fullname: string;

    constructor(){
        this.userId="";
        this.fullname="";
    }
    setUserId(userId:string){
        this.userId = userId;
    }
    getUserId(){
        return this.userId;
    }
    setFullname(fullname:string){
        this.fullname = fullname;
    }
    getFullname(){
        return this.fullname;
    }
}