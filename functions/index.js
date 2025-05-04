import { onRequest } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2';
import express from 'express';
import auth from 'basic-auth';
import compare from 'tsscmp';
import { dirname } from 'path';
import { fileURLToPath } from 'url';

// Helper to get __dirname in ES Modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const FUNCTION_REGION = 'asia-northeast1'

// Set global options for all functions (region, secrets, etc.)
setGlobalOptions({ region: FUNCTION_REGION });
const expressApp = express()

const basicAuthMiddleware = (req, res, next) => {
  const expectedUser = process.env.BASIC_AUTH_USER
  const expectedPass = process.env.BASIC_AUTH_PASSWORD

  if (!expectedUser || !expectedPass) {
    console.error('Basic auth secrets (BASIC_AUTH_USER, BASIC_AUTH_PASSWORD) are not defined.')
    return res.status(500).send('Internal Server Error: Auth configuration missing.')
  }

  const credentials = auth(req) 

  if (!credentials || !compare(credentials.name, expectedUser) || !compare(credentials.pass, expectedPass)) {
    res.statusCode = 401
    res.setHeader('WWW-Authenticate', 'Basic realm="Enter credentials"') 
    res.end('Access denied')
  } else {
    next()
  }
}

expressApp.use(basicAuthMiddleware)
expressApp.use(express.static(__dirname + '/public/'))

export const app = onRequest(
  {
    secrets: ['BASIC_AUTH_USER', 'BASIC_AUTH_PASSWORD'], // Define secrets here (v2 supports :latest implicitly or explicitly if needed)
    // You can add other options like memory, timeoutSeconds etc. here
  }, expressApp)