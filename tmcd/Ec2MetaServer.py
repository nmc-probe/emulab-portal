from BaseHTTPServer import BaseHTTPRequestHandler
import urlparse
import traceback
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

	    if folder != "":
	        folders.append(folder)
	    if only_path=="/":
		break;

        folders.reverse()
        print folders

        try:
            message = self.handle_req(folders, self.metas)
            message = message + "\n"
        except Exception as e:
            print traceback.format_exc()
            self.send_response(404)
            self.end_headers()
            return

        self.send_response(200)
        self.end_headers()
        self.wfile.write(message)
        return

    def listmetas(self, metas):
        message = "\n".join(map(lambda x: x + "/" if (x == "public-keys" or not(callable(metas[x])))  else x,
                        metas.keys()));
        return message

    def handle_req(self, arg, metas):
        if callable(metas):
            return metas(self, arg)
        elif len(arg) == 0:
            return self.listmetas(metas);
        else:
            return self.handle_req(arg[1:], metas[arg[0]])

    def do_userdata(self):
        #TODO
        return "\n";

    def doamiid(self, arg):
        cursor = self.cnx.cursor()
        ip = self.client_address[0]
        cursor.execute("select osname from os_info "
            "join nodes on os_info.osid = nodes.osid "
            "join interfaces on nodes.node_id=interfaces.node_id "
            "where interfaces.ip=%s", (ip,));
        if cursor.with_rows:
            ami_id = cursor.fetchone()
            ami_id = ami_id[0]
        else:
            ami_id = ""
        cursor.close()
        return ami_id;

    def dolocal_hostname(self, args):
        cursor = self.cnx.cursor()
        ip = self.client_address[0]
        cursor.execute("select vname,eid,pid from reserved join interfaces on interfaces.node_id=reserved.node_id"
            " where interfaces.ip=%s",(ip,))
        if cursor.with_rows:
            node_id = cursor.fetchone()
        else:
            cursor.close()
            return ""

        cursor.close()
        return node_id[0] + "." + node_id[1] + "." + node_id[2] + "." + "emulab.net"

    def doavail(self, args):
        #TODO
        return "emulab"


    def domacs(self, args):
        #TODO
        return "324AF"

    def domac(self, args):
        cursor = self.cnx.cursor()
        ip = self.client_address[0]
        cursor.execute("select mac from interfaces"
            " where interfaces.ip=%s",(ip,))
        if cursor.with_rows:
            mac = cursor.fetchone()
        else:
            cursor.close()
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
            cursor.close()
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
                cursor.close()
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
                cursor.close()
                return ""

            cursor.close()
            return key[0]

    metas = {
        "latest" : {
            "meta-data" : {
                "placement" : {"availability-zone" : doavail},
                "ami-id": doamiid,
                "local-hostname" : dolocal_hostname,
                "public-hostname":dolocal_hostname,
                "network": {"interfaces": {"macs" : domacs}},
                "mac":domac,
                "instance-id":doinstance_id,
                "public-keys": dopublic_keys },
            "user-data" : do_userdata
        }
    }


if __name__ == '__main__':
    from BaseHTTPServer import HTTPServer
    server = HTTPServer(('155.98.36.155', 8787), Ec2MetaHandler)
    print 'Starting server, use <Ctrl-C> to stop'
    server.serve_forever()

