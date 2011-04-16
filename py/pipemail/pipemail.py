#!/usr/bin/python
"""Pipes the result and status of a started process into an email.

This is useful for starting builds/syncs and getting an email notification.
"""

import smtplib
import markup
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email.header import Header
from email import Encoders
from StringIO import StringIO
from optparse import OptionParser
import subprocess
import sys
import os
import select
import fcntl
import errno
import locale
import getpass
import platform
import time

__license__ = "GPL"
__version__ = "1.0.0"
__maintainer__ = "Andrei Warkentin"
__email__ = "andrey.warkentin@gmail.com"
__status__ = "Production"

#
# This config should "just work" for gmail/google apps users.
# SMTP server address is from MX record for domain.
#

mail_config = {
   'user' : 'fjnh84@motorola.com',
   'server' : 'gmail-smtp-in.l.google.com',
   'tls' : False,
   'auth' : False,
   'pass' : None
}

#
# If you have a dynamic IP or there are other reasons,
# why the MTA rejects you, you need to use an MSA and auth.
# Something like this. Server address is same as used to
# configure your MUA.
#
#
#mail_config = {
#   'user' : 'fjnh84@motorola.com',
#   'server' : 'smtp.gmail.com',
#   'tls' : True,
#   'auth' : True,
#   'pass' : 'XXXXX'
#}
#

def mail(config, encoding, subject, body, out_data, err_data):
   msg = MIMEMultipart()
   msg.set_charset(encoding)
   subject = Header(subject, encoding)
   msg['From'] = config['user']
   msg['To'] = config['user']
   msg['Subject'] = subject

   part = MIMEBase('text', 'html', _charset=encoding)
   part.set_payload(body)
   Encoders.encode_base64(part)
   msg.attach(part)

   if not out_data is None:
      part = MIMEText(out_data, _charset=encoding)
      part.add_header('Content-Disposition', 'attachment', filename='stdout.txt')
      msg.attach(part)

   if not err_data is None:
      part = MIMEText(err_data, _charset=encoding)
      part.add_header('Content-Disposition', 'attachment', filename='stderr.txt')
      msg.attach(part)

   port = 25
   if config['auth']:
      port = 587
   mailServer = smtplib.SMTP(config['server'], port)
   if config['tls']:
      mailServer.ehlo()
      mailServer.starttls()
      mailServer.ehlo()
   if config['auth']:
      mailServer.login(config['user'], config['pass'])
   mailServer.sendmail(config['user'], config['user'], msg.as_string())
   mailServer.close()

def process_more(fd, strio, suppress_con, is_err):
   errdone = False
   more = True
   data = ""
   while more:
      try:
         data = os.read(fd, 1024)
         if data == "":
            errdone = True
            more = False
         else:
            if not suppress_con:
               if is_err:
                  sys.stderr.write(data)
               else:
                  sys.stdout.write(data)
            strio.write(data)
      except OSError, err:
         if err.errno == errno.EAGAIN or err.errno == errno.EWOULDBLOCK:
            more = False
         elif err.errno != errno.EINTR:
            errdone = True
      return errdone

def get_output(args, separate, suppress_con):
   time_wall = time.time()
   p = subprocess.Popen(args, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
   fdo = p.stdout.fileno()
   fde = p.stderr.fileno()
   fcntl.fcntl(fde, fcntl.F_SETFL, fcntl.fcntl(fde, fcntl.F_GETFL) | os.O_NONBLOCK)
   fcntl.fcntl(fdo, fcntl.F_SETFL, fcntl.fcntl(fdo, fcntl.F_GETFL) | os.O_NONBLOCK)
   rfd = [fde, fdo]
   outdone = False
   errdone = False

   outio = StringIO()
   errio = outio
   if separate:
      errio = StringIO()

   while True:
      if not errdone:
         errdone = process_more(fde, errio, suppress_con, True)
         
      if not outdone:
         outdone = process_more(fdo, outio, suppress_con, False)
            
      if errdone and outdone:
         break

      select.select(rfd, [], [])
   status = p.wait()
   time_wall = time.time() - time_wall
   if not separate:
      errio = None
   return (status, outio, errio, time_wall)

def process_output(io, line_max):
   cut = False
   processed_io = StringIO()
   io.seek(0)
   lines = io.readlines()
   count = len(lines)

   #
   # If output too big, show last line_max lines.
   # -1 is a special value to show all lines.
   #

   if count > line_max > -1:
      cut = True
      lines = lines[count - line_max:]

   processed_io.write(''.join(lines))
   return (processed_io, cut)

def format_time(seconds):
    hours = int(seconds // 3600)
    seconds -= 3600 * hours
    minutes = int(seconds // 60)
    seconds -= 60 * minutes
    return "{0}h {1}m {2} seconds".format(hours, minutes, seconds)

def main():
   encoding = locale.getpreferredencoding()
   parser = OptionParser(usage="usage: %prog [options] cmd [cmd arguments]")
   parser.disable_interspersed_args()
   parser.add_option('-l', '--lines', dest='lines', type='int', help='send maximum last stdout+stderr lines in email (-1 for max)', metavar='LINES', default=50)
   parser.add_option('-c', '--no-console', dest='supress_con', action='store_true', help="don't output to stdout/stderr", default=False)
   parser.add_option('-s', '--separate', dest='separate', action='store_true', help="keep stderr separate from stdout and send both as attachments", default=False)
   (options, process_args) = parser.parse_args()

   if not len(process_args) >= 1:
      parser.print_usage()
      sys.exit(1)

   try:
      process_status, process_out, process_err, time_wall = get_output(process_args, options.separate, options.supress_con)
   except OSError, err:
      sys.stderr.write("Error while starting child process: {0}\n".format(err.strerror))
      sys.exit(2)
   process_cmd = ' '.join(process_args)

   cut = False
   if not options.separate:
      process_out, cut = process_output(process_out, options.lines)

   process_out_string = None
   if process_out.tell() != 0:
      process_out_string = process_out.getvalue()
   process_err_string = None
   if (not process_err is None) and (process_err.tell() != 0):
      process_err_string = process_err.getvalue()

   page = markup.page()
   page.h3("Command: {0}".format(process_cmd))
   page.h3("Return status: {0}".format(process_status))
   page.h3("Time: {0}".format(format_time(time_wall)))
   if options.separate:
      if (process_out_string is None) and (process_err_string is None):
         page.i("... no stdout/stderr output to attach ...")
      else:
         page.i("... see attachments for logs ...")
   else:
      if process_out_string is None:
         page.i("... no stdout/stderr output  ...")
      else:
         if cut:
            page.i("... showing last {0} lines...".format(options.lines))
         page.hr()
         page.pre(markup.escape(process_out_string))

         # 
         # This ensures the output isn't attached as an attachment.
         # If we're ever in this code path, process_err_string is guaranteed
         # to be None, since process_err is None, since get_output was invoked
         # with options.separate = False.
         #

         process_out_string = None
         page.hr()

   subject = "{0}@{1}: {2}".format(getpass.getuser(), platform.node(),process_cmd)
   mail(mail_config, encoding, subject, page(), process_out_string, process_err_string)

if __name__ == '__main__':
   main()
