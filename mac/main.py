from _webkit_callback import eval_js
import json

class Server(object):

    def __init__(self, webkit_handle):
        self.webkit_handle = webkit_handle

    def eval_js(self, js):
        return eval_js(self.webkit_handle, js)

    def send_message(self, message):
        return self.eval_js('pythonMessage(%s)' % json.dumps(message))

    def recieve_message(self, message_string):
        return

def main(handle):
    return Server(handle)
