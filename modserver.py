#modified by pawlrus for redis sessions
# Copyright (c) 2018 Yubico AB
# All rights reserved.
#
#   Redistribution and use in source and binary forms, with or
#   without modification, are permitted provided that the following
#   conditions are met:
#
#    1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

"""
Example demo server to use a supported web browser to call the WebAuthn APIs
to register and use a credential.

See the file README.adoc in this directory for details.

Navigate to https://localhost:5000 in a supported web browser.
"""
from __future__ import print_function, absolute_import, unicode_literals

from fido2.webauthn import PublicKeyCredentialRpEntity
from fido2.client import ClientData
from fido2.server import Fido2Server
from fido2.ctap2 import AttestationObject, AuthenticatorData
from fido2 import cbor
from flask import Flask, session, request, redirect, abort, make_response

from flask_session_plus import Session

import bcrypt as bc

#import redis

import os

# key + salt to encrypt cookies, could be redis stored or otherwise dynamic and shared
bc_key = b"9D42A4E5-D713-4259-BFC2-406FEA141056"
salt = b"1EECEEE9-10D3-4247-AB97-CD0BF19783C4"

#flask init
app = Flask(__name__, static_url_path="")
app.secret_key = os.urandom(32)  # Used for session.
#app.config['SESSION_TYPE'] = 'redis'
#app.config['SESSION_REDIS'] = redis.from_url('127.0.0.1:6379')
#hardware auth session
cookiename = 'hwauth'
app.config['SESSION_CONFIG'] = [
    {
        'cookie_name': cookiename,
        'session_type': 'redis',
        'cookie_secure': 'True',
        'session_fields': ['user_id', 'user_data', '_id'],
        'client': '127.0.0.1:6379',
        'collection': 'sessions',
    }]

#Flask-session init
session_store = Session()
session_store.init_app(app)

#https alternative
# r = redis.Redis(host='xxxxxx.cache.amazonaws.com', port=6379, db=0,
#                     ssl=True,
#                     ssl_ca_certs='/etc/ssl/certs/ca-certificates.crt')


rp = PublicKeyCredentialRpEntity("localhost", "Demo server")
server = Fido2Server(rp)


# Registered credentials are stored globally, in memory only. Single user
# support, state is lost when the server terminates.
credentials = []


@app.route("/")
def index():
    print(request.cookies)
    #does browser have cookie needed?
    if cookiename in request.cookies:
        # get cookie value
        cookie = request.cookies[cookiename]
        #is cookie in session store?
        if cookie in session_store:
            #auth complete move user to 2nd server
            return redirect("https://localhost:8080", code=302)
    #get sessions from redis, if good then display stuff, fail redirect to other server
    else:
        # send user to webauth page
        return redirect("/index.html")


@app.route("/api/register/begin", methods=["POST"])
def register_begin():
    registration_data, state = server.register_begin(
        {
            "id": b"user_id",
            "name": "a_user",
            "displayName": "A. User",
            "icon": "https://example.com/image.png",
        },
        credentials,
        user_verification="discouraged",
        authenticator_attachment="cross-platform",
    )

    session["state"] = state
    print("\n\n\n\n")
    print(registration_data)
    print("\n\n\n\n")
    return cbor.encode(registration_data)


@app.route("/api/register/complete", methods=["POST"])
def register_complete():
    data = cbor.decode(request.get_data())
    client_data = ClientData(data["clientDataJSON"])
    att_obj = AttestationObject(data["attestationObject"])
    print("clientData", client_data)
    print("AttestationObject:", att_obj)

    auth_data = server.register_complete(session["state"], client_data, att_obj)

    credentials.append(auth_data.credential_data)
    print("REGISTERED CREDENTIAL:", auth_data.credential_data)
    return cbor.encode({"status": "OK"})


@app.route("/api/authenticate/begin", methods=["POST"])
def authenticate_begin():
    if not credentials:
        abort(404)

    auth_data, state = server.authenticate_begin(credentials)
    session["state"] = state
    return cbor.encode(auth_data)


@app.route("/api/authenticate/complete", methods=["POST"])
def authenticate_complete():
    if not credentials:
        abort(404)

    data = cbor.decode(request.get_data())
    credential_id = data["credentialId"]
    client_data = ClientData(data["clientDataJSON"])
    auth_data = AuthenticatorData(data["authenticatorData"])
    signature = data["signature"]
    print("clientData", client_data)
    print("AuthenticatorData", auth_data)

    server.authenticate_complete(
        session.pop("state"),
        credentials,
        credential_id,
        client_data,
        auth_data,
        signature,
    )
    print("ASSERTION OK")

    #add sesession code here for successful
    cookie = os.urandom(32)
    session_info = {'uid': os.urandom(32), 'sid': os.urandom(12), 'data' : 'cant touch this, ba nanana'}
    session_store[cookie] = session_info
    resp = make_response(redirect("https://localhost:8080", code=302))
    resp.set_cookie(session_store[cookiename])

    return cbor.encode({"status": "OK"})

@app.errorhandler(404)
def page_not_found(e):
    if request.path.startswith('api') or request.path.startswith('authen') or request.path.startswith('index'):
        abort(404)
    # your processing here
    return 'Error 404'

@app.errorhandler(500)
def page_not_found(e):
    if request.path.startswith ('api') or request.path.startswith('authen') or request.path.startswith('index'):
        abort(500)
    # your processing here
    return 'Error 404'


if __name__ == "__main__":
    print(__doc__)
    app.run(ssl_context="adhoc", debug=False)