from BaseHTTPServer import BaseHTTPRequestHandler
import urlparse
import os
import mysql.connector


class Ec2MetaHandler(BaseHTTPRequestHandler):

    def __init__(self, req, ca, huh):
        self.cnx = mysql.connector.connect(user='tmcd',
                              database='tbdb', unix_socket='/tmp/mysql.sock')
        BaseHTTPRequestHandler.__init__(self,req,ca,huh)

    def do_GET(self):
        parsed_path = urlparse.urlparse(self.path)

        only_path = parsed_path.path
        folders=[]
        while 1:
            only_path,folder=os.path.split(only_path)

            if folder!="":
                folders.append(folder)
            else:
                if only_path!="":
                    folders.append(only_path)

                break

        folders.reverse()
        folders.pop(0) #Drop /

        #Ignore first arg - the metadata version
        #TODO throw in some verification
        folders.pop(0)

        if len(folders) == 0:
            self.send_response(404)
            self.end_headers()
            return

        #User-data or meta-data
        if folders[0] == "user-data":
            folders.pop(0)
            message = self.handle_user()
        elif folders[0] == "meta-data":
            folders.pop(0)
            message = self.handle_meta(folders)

        self.send_response(200)
        self.end_headers()
        self.wfile.write(message)
        return

    def handle_meta(self, arg):
        if arg == "":
            return self.listmetas()
        else:
            return (Ec2MetaHandler.topmetas[arg[0]](self,arg[1:]))


    def handle_user(self):
        return self.client_address[0]


    def listtopmetas(self):
        message = "\n".join(Ec2MetaHandler.topmetas.viewkeys())
        return message


    def dolocal_hostname(self, args):
        cursor = self.cnx.cursor()
        ip = self.client_address[0]
        cursor.execute("select vname,eid,pid from reserved join interfaces on interfaces.node_id=reserved.node_id"
            " where interfaces.ip=%s",(ip,))
        if cursor.with_rows:
            node_id = cursor.fetchone()
        else:
            return ""

        cursor.close()
        return node_id[0] + "." + node_id[1] + "." + node_id[2] + "." + "emulab.net"

    def domac(self, args):
        cursor = self.cnx.cursor()
        ip = self.client_address[0]
        cursor.execute("select mac from interfaces"
            " where interfaces.ip=%s",(ip,))
        if cursor.with_rows:
            mac = cursor.fetchone()
        else:
            return ""

        cursor.close()
        split = [mac[0][i:i+2] for i in range(0, len(mac[0]),2)]
        return ":".join(split)

    def doinstance_id(self, args):
        cursor = self.cnx.cursor()
        ip = self.client_address[0]
        cursor.execute("select uuid from interfaces"
            " where interfaces.ip=%s",(ip,))
        if cursor.with_rows:
            uuid = cursor.fetchone()
        else:
            return ""

        cursor.close()
        return uuid[0]


    def dopublic_keys(self, args):
        if len(args) == 0:
            #Throw out all the users. Hope the stuff don't change between queries
            cursor = self.cnx.cursor()
            ip = self.client_address[0]
            cursor.execute("select user_pubkeys.uid,user_pubkeys.idx from user_pubkeys "
                "join group_membership on group_membership.uid = user_pubkeys.uid "
                "join experiments on experiments.pid=group_membership.pid AND experiments.gid=group_membership.gid "
                "join reserved on reserved.exptidx=experiments.idx "
                "join interfaces on reserved.node_id=interfaces.node_id "
                "where interfaces.ip=%s;", (ip,));

            list = ""
            ctr = 0
            if cursor.with_rows:
                for (user,uid) in cursor:
                    list = list + str(ctr) + "=" + str(user) + str(uid) + "\n"
                    ctr = ctr+1
            else:
                return ""

            cursor.close()
            return list
        elif len(args) == 1:
            #TODO: Verify ig idx is within limits
            return "openssh-key"
        elif len(args) == 2:
            val = int(args[0])
            cursor = self.cnx.cursor()
            ip = self.client_address[0]
            cursor.execute("select user_pubkeys.pubkey from user_pubkeys "
                "join group_membership on group_membership.uid = user_pubkeys.uid "
                "join experiments on experiments.pid=group_membership.pid AND experiments.gid=group_membership.gid "
                "join reserved on reserved.exptidx=experiments.idx "
                "join interfaces on reserved.node_id=interfaces.node_id "
                "where interfaces.ip=%s limit " + str(val) +", 1;", (ip,));

            if cursor.with_rows:
                key = cursor.fetchone()
            else:
                return ""

            cursor.close()
            return key[0]









    topmetas = {
        "local-hostname":dolocal_hostname,
        "public-hostname":dolocal_hostname,
        "mac":domac,
        "instance-id":doinstance_id,
        "public-keys":dopublic_keys}

if __name__ == '__main__':
    from BaseHTTPServer import HTTPServer
    server = HTTPServer(('', 8080), Ec2MetaHandler)
    print 'Starting server, use <Ctrl-C> to stop'
    server.serve_forever()
