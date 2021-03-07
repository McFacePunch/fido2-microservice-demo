# by pawlrus
# testing page to show session store use

#! /usr/bin/python
from __future__ import print_function, absolute_import, unicode_literals

import sys, os
sys.path.append("/var/www/apache-flask")

from flask import Flask, session, redirect, request, make_response

from redis import Redis


#flask init
app = Flask(__name__, static_url_path="")
app.secret_key = os.urandom(32)  # Used for local (to server) sessions

#hardware webauth session
cookiename = 'hwauth'
#rd = Redis(host='localhost', port=6379) # host= redis if tls, this is for ssh port forward
rd = Redis(host='redis',port=6379)#, db=0, ssl=True,
                #ssl_ca_certs='/etc/ca.crt')

win = """h1 style="color: #5e9ca0;">Welcome to the "secure" Page!</h1>
<p>&nbsp;</p>
<p>This page can only be accessed by successful webauth and being forwarded to a 2nd webserver that uses a session store to validate your cookies.</p>
"""

@app.route("/")
def index():
    print(request.cookies)
    #print(session[cookiename])
    #does browser have cookie needed?
    if cookiename in request.cookies:
        cookie_val = request.cookies[cookiename]
        #is cookie in session store?
        session_info = rd.hgetall(cookie_val)
        print(session_info)
        if b'uid' and b'sid' and b'data' in session_info:
            print("win-page success!")
            #data = session_info['data']
            #resp = make_response(redirect("https://localhost:8080", code=301))
            #resp.set_cookie(cookiename, b64cookie)
            return make_response(win)
            #return 'Hello! Welcome to the secure page!\nData: '+data
        else:
            # send no session/expired to webauth server
            return redirect("https://localhost:443/", code=301)
    #get sessions from redis, if good then display stuff, fail redirect to other server
    else:
        # send no session to webauth server
        return redirect("https://localhost:443/", code=301)

@app.route("/logout")
def logout():
    print(request.cookies)
    #does browser have cookie needed?
    if cookiename in request.cookies:
        cookie_val = request.cookies[cookiename]
        #is cookie in session store?
        session_info = rd.hgetall(cookie_val)
        print(session_info)
        if b'uid' and b'sid' and b'data' in session_info:
            rd.hdel(cookie_val)
            # resp.delete_cookie('username')
            print("Logout success!")
            return make_response("Logout complete!")
        else:
            print("cookie value not found, expired?")
            return #"cookie value not found, expired?"
    else:
        print("no cookie to logout...")
        return #"No coookie to logout!"

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
