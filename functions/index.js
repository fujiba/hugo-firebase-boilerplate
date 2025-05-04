const functions = require('firebase-functions')
const express = require('express')
const auth = require('basic-auth')
const compare = require('tsscmp')
const FUNCTION_REGION = 'asia-northeast1'

const app = express()

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

app.use(basicAuthMiddleware)
app.use(express.static(__dirname + '/public/'))

exports.app = functions
  .region(FUNCTION_REGION)
  .runWith({
    secrets: ['BASIC_AUTH_PASSWORD', 'BASIC_AUTH_USER']
  })
  .https.onRequest(app)
