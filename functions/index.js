const functions = require('firebase-functions')
const express = require('express')
const basicAuth = require('basic-auth-connect')
const FUNCTION_REGION = 'asia-northeast1'

const app = express()

app.all(
  '/*',
  basicAuth(function (user, password) {
    return user === process.env.BASIC_AUTH_USER && password === process.env.BASIC_AUTH_PASSWORD
  })
)

app.use(express.static(__dirname + '/public/'))

exports.app = functions
  .region(FUNCTION_REGION)
  .runWith({
    secrets: ['BASIC_AUTH_PASSWORD', 'BASIC_AUTH_USER']
  })
  .https.onRequest(app)
