#! /usr/bin/python

import sys
sys.path.append("/var/www/apache-flask")

from srv import modserver as srv_obj

application = srv_obj.app

# if __name__ == "__main__":
#     print(__doc__)
#     a.server
#     application.app.run(debug=False)