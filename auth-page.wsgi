#by pawlrus
#testing page to show distributed session management

#! /usr/bin/python
from __future__ import print_function, absolute_import, unicode_literals

import sys
sys.path.append("/var/www/apache-flask")

#from srv import server as srv_obj

#application = srv_obj.app


from flask import Flask, session, redirect, request
from flask_session_plus import Session

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
            session = session_store[cookie]
            data = session['data']
            print("Auth success!")
            return 'Hello! Welcome to the secure page!\n'+data
    #get sessions from redis, if good then display stuff, fail redirect to other server
    else:
        # send no session to webauth server
        return redirect("https://localhost", code=302)

@app.route("/logout")
def logout():
    print(request.cookies)
    #does browser have cookie needed?
    if cookiename in request.cookies:
        #get cookie value
        cookie = request.cookies[cookiename]
        #is cookie in session store?
        if cookie in session_store:
            session.pop(cookie, None)
            print("Logout success!")
            return "Logout complete!"
        else:
            print("cookie value not found, expired?")
            return "cookie value not found, expired?"
    else:
        print("no cookie to logout...")
        return "No coookie to logout!"

@app.errorhandler(404)
def page_not_found():
    # your processing here
    return 'Error 404'

@app.errorhandler(500)
def page_not_found():
    # your processing here
    return 'Error 404'


application = app

# if __name__ == "__main__":
#     print(__doc__)
#     app.run(ssl_context="adhoc", debug=False)
