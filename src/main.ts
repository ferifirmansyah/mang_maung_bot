'use strict';
declare var require:any;
declare var __dirname:any;
var process = require('process');
var vPath = require("path");
export var vEnv = process.env.NODE_ENV || require(vPath.join(__dirname, 'config', 'mode.json'))['mode'];
export var config = require(vPath.join(__dirname, 'config', 'config.json'))[vEnv];
import { Routing } from './route';
import { Logging } from './services/logging.service';
import { SequelizeService } from './services/sequelize.service';
import { DataAccessService } from './services/data-access.service';


var multipart = require('connect-multiparty');
var express = require('express');
var bodyParser = require('body-parser');
var vValidator = require('validator');
const app = express();
const router = express.Router();
const port: number = process.env.PORT || config.port || 4000;
let seq: SequelizeService = new SequelizeService();
let allow: string;
var multipartMiddleware = multipart({ uploadDir: config.storage });
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(function (req:any, res:any, next:any) {
    //update
    let origin = req.get('origin');
    res.header("Access-Control-Allow-Origin", origin);
    res.header("Access-Control-Allow-Credentials", "true");
    res.header("Access-Control-Allow-Headers",
        "Access-Control-Allow-Origin, X-Requested-With, Content-Type, Accept,authorization,Proxy-Authorization,X-session");
    res.header("Access-Control-Expose-Headers", "accessToken,created,Content-Disposition");
    res.header("Access-Control-Allow-Methods", "GET,PUT,DELETE,POST");
    res.header("X-XSS-Protection", "1");
    res.header("X-Content-Type-Options", "nosniff");
    res.header("Content-Security-Policy", "object-src 'none';img-src 'self';media-src 'self';frame-src 'none';font-src 'self' data:;connect-src 'self';style-src 'self'");

    Logging('incoming request host : ' + req.headers.host);
    Logging('Incoming request method : ' + req.method);
    Logging('Incoming request path : ' + req.path);
    Logging('cookies : ' + JSON.stringify(req.cookies));
    
    if (req.method === 'POST' || req.method === 'PUT' || req.method === 'DELETE') {
        // ---------------------------------------------------------------
        for (let param in req.body) {
            if (typeof req.body[param] === 'string')
                req.body[param] = vValidator.escape(req.body[param]);
        }
    }
    else if (req.method === 'GET') {
        for (let param in req.query) {
            if (typeof req.query[param] === 'string' && param != 'filepath')
                req.query[param] = vValidator.escape(req.query[param]);
        }
        for (let param in req.params) {
            if (typeof req.params[param] === 'string')
                req.params[param] = vValidator.escape(req.params[param]);
        }
    }
    next();
});
Routing(router,multipartMiddleware);
app.use('/api', router);
app.listen(port);
Logging('listening : ' + port);