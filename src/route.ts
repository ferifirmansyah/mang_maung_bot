import {AppController} from './controller/app/app.controller';
import {AdminController} from './controller/admin/admin.controller';
import {Token} from './services/token.service';
export function Routing(router:any,multipart:any){
    const appController: AppController = new AppController();
    const adminController: AdminController = new AdminController();
    const tokenService: Token = new Token();

    router.post('/admin/authorization',adminController.login);
    router.post('/admin/changepass',tokenService.verifyToken,adminController.changePassword);
    router.post('/admin/upload',tokenService.verifyToken,multipart,adminController.upload);
    router.post('/admin/editfile',tokenService.verifyToken,multipart,adminController.editFile);
    router.post('/admin/deletefile',tokenService.verifyToken,adminController.deleteFile);
    router.get('/admin/getlist',tokenService.verifyToken,appController.getCatAndFile);
    router.post('/admin/category/add',tokenService.verifyToken,adminController.categoryAdd);
    router.post('/admin/category/update',tokenService.verifyToken,adminController.categoryUpdate);
    router.post('/admin/category/delete',tokenService.verifyToken,adminController.categoryDelete);
    
    router.get('/app/download',appController.download);
    router.get('/app/getlist',appController.getCatAndFile);
}