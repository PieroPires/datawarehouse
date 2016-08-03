from oauth2client.client import OAuth2WebServerFlow
from oauth2client.tools import run
from oauth2client.file import Storage

CLIENT_ID = '202379785889-9ln68an8pr9o7ldlckaev64bjej76mnm.apps.googleusercontent.com'
CLIENT_SECRET = '7bf431wrB0zWxGyhDTRonKXl'

flow = OAuth2WebServerFlow(
          client_id = CLIENT_ID,
          client_secret = CLIENT_SECRET,
          scope = 'https://spreadsheets.google.com/feeds https://docs.google.com/feeds',
          redirect_uri = 'http://localhost:8080/'
       )

storage = Storage('creds.data')
credentials = run(flow, storage)
print "access_token: %s" % credentials.access_token