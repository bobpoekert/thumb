from _webkit_callback import eval_js
import json
import threading, time
import traceback, inspect

print 'loading module'

class Server(object):

    def __init__(self, webkit_handle):
        try:
            self.webkit_handle = webkit_handle
            #self.thread = threading.Thread(target=self.delay_test)
            #self.thread.start()
            #print self.eval_js('document.write(app.callPython("test", "hello"))')
            print repr(self.eval_js('typeof(window.container.callPython("test", "foo")'))
        except:
            traceback.print_exc()

    def delay_test(self):
        time.sleep(0.5)
        print 'delay'
        self.send_message('hello')

    def eval_js(self, js):
        return eval_js(self.webkit_handle, js)

    def send_message(self, message):
        print 'sending message %s' % message
        return self.eval_js('pythonMessage(%s)' % json.dumps(message))

    def recieve_message(self, message_string):
        return

    def test(self, inp):
        try:
            print 'called test'
            return 'you said: %s' % inp
        except Exception, e:
            return repr(e)

def main(handle):
    print 'called main'
    return Server(handle)
