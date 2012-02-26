/*
 * EMULAB-COPYRIGHT
 * Copyright (c) 2010 University of Utah and the Flux Group.
 * All rights reserved.
 */

/* This program implements the Disk agent for Emulab.
 * It listens to objtype "disk" and creates/modifies/ device mapper(DM)
 * disks. Also, we can inject errors of various types on these DM disks.
 */

#include <cassert>
#include <cmath>
#include <ctime>
#include <string>
#include <map>
#include <list>
#include <vector>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <fstream>
#include <cerrno>
#include "log.h"
#include <cstdio>
#include <algorithm>
#include <ctype.h>
extern "C" {
	#include "libdevmapper.h"
}

#ifdef HAVE_ELVIN
#include <elvin/elvin.h>
#endif

#include <sys/time.h>

using namespace std;

// For getopt
#include <unistd.h>

#include "event.h"
#include "tbdefs.h"
#define LINE_SIZE 4096
#define MAX_BUFFER 4096
#define err(msg, x...) fprintf(stderr, msg "\n", ##x)

/**
 * Structure used to track individual agents.
 */
struct diskinfo {
    char        name[TBDB_FLEN_EVOBJNAME];

    char           *initial_cmdline;
    char           *cmdline;
	char 		   *type;
	char 		   *initial_type;
	char		   *mountpoint;
	char		   *initial_mountpoint;
	char		   *parameters;
	char		   *initial_parameters;	
    int     pid;
    struct diskinfo *next;
};

/**
 * Refers to the head of the agent list.
 */
static struct diskinfo *diskinfos;


char * _table = NULL;

enum { EVENT_BUFFER_SIZE = 5000 };

namespace g
{
  std::string experimentName;
  bool debug = false;
}

vector<string> device_params;

void readArgs(int argc, char * argv[]);
void usage(char * name);

/**
 * Parse the configuration file containing the list of agents and their initial
 * settings.
 *
 * @param filename The name of the config file.
 * @return Zero on success, -1 otherwise.
 */
static int  parse_configfile(char *filename);
static void set_disk(struct diskinfo *dinfo, char *args);



// Reads the map file, initializes the pipe and pipeVault data
// structure, and sets up the two subscription strings for events.
void writePidFile(string const & pidFile);
void initEvents(string const & server, string const & port,
                string const & keyFile, string const & subscription,
                string const & group);
void subscribe(event_handle_t handle, address_tuple_t eventTuple,
               string const & subscription, string const & group);
void callback(event_handle_t handle,
              event_notification_t notification, void *data);
void start(string);

/**
 * Handler for the TIME start event.  This callback will stop all running
 * programs, reset the agent configuration to the original version specified in
 * the config file, and delete all the files in the log directory.
 *
 * @param handle The connection to the event system.
 * @param notification The start event.
 * @param data NULL
 */
static void start_callback(event_handle_t handle,
                   event_notification_t notification,
                   void *data);


//DM Device routines
int create_dm_device(struct diskinfo *dinfo, char *);
int run_dm_device(struct diskinfo *dinfo, char *);
int modify_dm_device(struct diskinfo *dinfo, char *);
int resume_dm_device(char *);
static int _device_info(char *);
static int _parse_line(struct dm_task *, char *, const char *,int);
static int _parse_file(struct dm_task *, const char *);
static void _display_info_long(struct dm_task *,  struct dm_info *);
int _get_device_params(const char *);
string exec_output(string);
string itos(int );


/**
 * Dump the diskinfos list to standard out.
 */
static void
dump_diskinfos(void)
{
    struct diskinfo *pi;

    for (pi = diskinfos; pi != NULL; pi = pi->next) {
        printf(
               "  Name: %s\n"
               "  type: %s\n"
               "  mountpoint: %s\n"
               "  parameters: %s\n"
               "  command: %s\n",
               pi->name ? pi->name : "(not set)",
               pi->type ? pi->type : "(not set)",
               pi->mountpoint ? pi->mountpoint : "(not set)",
               pi->parameters ? pi->parameters : "(not set)",
               pi->cmdline ? pi->cmdline : "(not set)"
               );
    }
}

static struct diskinfo *
find_agent(char *name)
{
    struct diskinfo *dinfo, *retval = NULL;

    dinfo = diskinfos;
    while (dinfo) {
        if (! strcmp(dinfo->name, name)) {
            retval = dinfo;
            break;
        }
        dinfo = dinfo->next;
    }

    return retval;
}

int main(int argc, char * argv[])
{
  cerr << "Beginning program" << endl;
  readArgs(argc, argv);
  return 0;
}

void readArgs(int argc, char * argv[])
{
  cerr << "Processing arguments" << endl;
  string server;
  string port;
  char *logfile = NULL;
  string pidfile;
  char *configfile;
  string keyFile;
  string tokenfile;
  string subscription;
  string vnode;
  string group;
  string LOGDIR = "/local/logs";

  int isops, isplab;
	
  // Prevent getopt from printing an error message.
  opterr = 0;

  /* get params from the optstring */
  char const * argstring = "hds:p:l:u:i:e:c:k:o:g:v:t:P";
  int option = getopt(argc, argv, argstring);
  while (option != -1)
  {
    switch (option)
    {
	case 'h':
	  usage(argv[0]);
	  break;
    case 'd':
      g::debug = true;
      pubsub_debug = 1;
      break;
    case 's':
      server = optarg;
      break;
    case 'p':
      port = optarg;
      break;
	case 'l':
	  logfile = optarg;
	  break;
	case 'c':
	  configfile = optarg;
	  break;
    case 'e':
      g::experimentName = optarg;
      break;
    case 'k':
      keyFile = optarg;
      break;
    case 'u':
      subscription = optarg;
      break;
	case 'o':
	  LOGDIR = optarg;
	  break;
	case 'i':
	  pidfile = optarg;
	  break;
	case 't':
	  tokenfile = optarg;
	  break;
	case 'v':
	  vnode = optarg;
	  if(!(vnode == "ops"))
	  		isops = 1;
	  break;
	case 'P':
	  isplab = 1;
	  break;
    case 'g':
      group = optarg;
      break;
    default:
      usage(argv[0]);
      break;
    }
    option = getopt(argc, argv, argstring);
  }

  /*Check if all params are specified, otherwise, print usage and exit*/
  if(server == "" || g::experimentName == "")
      usage(argv[0]);

 /* if(g::debug)
	loginit(0, logfile);
  else {
	if(logfile)
		loginit(0, logfile);
	else
		loginit(1, "disk-agent");
  }*/
  //if(subscription == "")
	//subscription = "DISK";
	
  if (parse_configfile(configfile) != 0)
      exit(1);


  initEvents(server, port, keyFile, subscription, group);
}

void usage(char * name)
{
  cerr << "Usage: " << name << " -e proj/exp -s server [-h][-d] [-p port] "
       << "[-l logfile] [-c config file] [-i pidFile] [-k keyFile] [-u subscription] [-g group]" << endl;
  exit(-1);
}

void initEvents(string const & server, string const & port,
                string const & keyFile, string const & subscription,
                string const & group)
{
  cerr << "Initializing event system" << endl;
  string serverString = "elvin://" + server;
  event_handle_t handle;
  if (port != "")
  {
    serverString += ":" + port;
  }
  cerr << "Server string: " << serverString << endl;
  if (keyFile != "")
  {
    handle = event_register_withkeyfile(const_cast<char *>(serverString.c_str()), 0,
                                        const_cast<char *>(keyFile.c_str()));
  }
  else
  {
    handle = event_register_withkeyfile(const_cast<char *>(serverString.c_str()), 0, NULL);
  }
  if (handle == NULL)
  {
    cerr << "Could not register with event system" << endl;
    exit(1);
  }

  address_tuple_t eventTuple = address_tuple_alloc();

  subscribe(handle, eventTuple, subscription, group);

  address_tuple_free(eventTuple);


  /*
   * Begin the event loop, waiting to receive event notifications:
   */
 
  while(1) {
	if(event_main(handle) == 0)
		cerr << "Event main stopped!" << endl;
  }
}

void subscribe(event_handle_t handle, address_tuple_t eventTuple,
               string const & subscription, string const & group)
{
  char agentlist[MAX_BUFFER];
  bzero(agentlist, sizeof(agentlist));
  struct diskinfo *dinfo;

  string name = subscription;
  if (group != "")
  {
    name += "," + group;
  }
  /*
   * Cons up the agentlist for subscription below.
   */
  dinfo = diskinfos;
  while (dinfo) {

  	if (strlen(agentlist))
        strcat(agentlist, ",");
    	strcat(agentlist, dinfo->name);

        dinfo = dinfo->next;
  }

  eventTuple->objname = agentlist;//const_cast<char *>(name.c_str());
  eventTuple->objtype = TBDB_OBJECTTYPE_DISK;
  eventTuple->eventtype = 
				TBDB_EVENTTYPE_START ","
				TBDB_EVENTTYPE_RUN ","
				TBDB_EVENTTYPE_CREATE ","
				TBDB_EVENTTYPE_MODIFY;
  //eventTuple->eventtype = ADDRESSTUPLE_ANY;
  eventTuple->expt = const_cast<char *>(g::experimentName.c_str());
  eventTuple->host = ADDRESSTUPLE_ANY;
  eventTuple->site = ADDRESSTUPLE_ANY;
  eventTuple->group = ADDRESSTUPLE_ANY;
  //eventTuple->scheduler = 1;
  if (event_subscribe(handle, callback, eventTuple, NULL) == NULL)
  {
    cerr << "Could not subscribe to " << eventTuple->eventtype << " event" << endl;

  }
  
    eventTuple->objtype   = TBDB_OBJECTTYPE_TIME;
    eventTuple->objname   = ADDRESSTUPLE_ANY;
    eventTuple->eventtype = TBDB_EVENTTYPE_START;

    /*
     * Subscribe to the TIME start event we specified above.
     */
    if (! event_subscribe(handle, start_callback, eventTuple, NULL)) {
        cerr << "could not subscribe to event" << endl;
    }

 	dump_diskinfos(); 


}

void callback(event_handle_t handle,
              event_notification_t notification,
              void * data)
{
  char name[EVENT_BUFFER_SIZE];
  char type[EVENT_BUFFER_SIZE];
  char args[EVENT_BUFFER_SIZE];
  
  struct diskinfo *dinfo;

  struct timeval basicTime;
  gettimeofday(&basicTime, NULL);
  map<string, int> eventtype;

  eventtype["CREATE"]  = 0;
  eventtype["MODIFY"]  = 1;
  eventtype["STOP"]    = 2;
  eventtype["RUN"]     = 3;
  eventtype["START"]   = 3;

  double floatTime = basicTime.tv_sec + basicTime.tv_usec/1000000.0;
  ostringstream timeStream;
  timeStream << setprecision(3) << setiosflags(ios::fixed | ios::showpoint);
  timeStream << floatTime;
  string timestamp = timeStream.str();


  if (event_notification_get_string(handle, notification, const_cast<char *>("OBJNAME"), name, EVENT_BUFFER_SIZE) == 0)
  {
    cerr << timestamp << ": ERROR: Could not get the object name" << endl;
    return;
  }

  cerr << name << endl;

  if (event_notification_get_string(handle, notification, const_cast<char *>("EVENTTYPE"), type, EVENT_BUFFER_SIZE) == 0)
  {
    cerr << timestamp << ": ERROR: Could not get the event type" << endl;
    return;
  }
  string event = type;
  cerr << event << endl; 
	 
  event_notification_get_string(handle, notification,const_cast<char *>("ARGS"), args, EVENT_BUFFER_SIZE); 
  
  cerr << args << endl; 

  /* DEBUG */
  cout <<"Config file"<<endl;
  dump_diskinfos(); 	
 
  /* Find the agent and */
  dinfo = find_agent(name);
  if (!dinfo) {
      cout << "Invalid disk agent: "<< name <<endl;
      return;
  }

  /* Call the event handler routine based on the event */
  switch(eventtype[event])
  {
	case 0:
		/* Event is to create a dm disk */	
		if(!create_dm_device(dinfo, args))
			cout << "DM failed" << endl;
		event="";
		break;
  	case 1:
		/* Event is to modify the dm disk */
		if(!modify_dm_device(dinfo, args))
			cout << "DM failed" << endl;
		event="";
	 	break;	
	case 2:
		break;
	case 3:
		if(!run_dm_device(dinfo, args))
			 cout << "DM failed" << endl;
		event="";
		break;
	default:
		cout << "Don't recognize the event type" << endl;
  }
 
}

int run_dm_device(struct diskinfo *dinfo, char *args)
{
	struct dm_task *dmt;

	set_disk(dinfo, args);

	/* Check if the required parameters for this event is supplied 
	 */
	if(!dinfo->type || !dinfo->mountpoint) 
	{
		cerr << "Disk type of mountpoint not specified" <<endl;
		return 0;
	}
		
    /* DEBUG */
    cout <<"Event START/RUN"<<endl;
    dump_diskinfos();


	if (_device_info(dinfo->name)) {
		/* DM device exists so we'll reload it with params supplied */
		uint64_t start=0, length=0;
	    char *target_type=NULL, *params=NULL;
		
		string params_str="", diskname="";
		stringstream split;

	 	if (!(dmt = dm_task_create(DM_DEVICE_RELOAD))) {
            cout << "in dm task create"<<endl;
            return 0;
        }		
		if ( !dm_task_set_name(dmt, dinfo->name)){
			dm_task_destroy(dmt);
            return 0;
		}
	
		if (!(_get_device_params(dinfo->name))) {
			dm_task_destroy(dmt);
            return 0;
		}
		cout << device_params[0] << device_params[1] << device_params[2] << device_params[3] << endl;
	
		start 		    = strtoul (device_params[0].c_str(),NULL,0);
		length 		    = strtoul (device_params[1].c_str(),NULL,0);
		target_type 	= dinfo->type;

		split		   << device_params[3];

		getline(split,diskname,' ');
 		params_str 	= diskname + " " + "0 "+ dinfo->parameters;
		cout << "diskname after "<<params_str<<endl;
		params 		= const_cast<char *>(params_str.c_str());

		cout <<start<<" "<<length<<" "<<target_type<<" "<<params<<endl;;	
		
		if (!dm_task_add_target(dmt, start, length, target_type, params)) {
				dm_task_destroy(dmt);
                return 0;
		}
		/* Now that we have the dm ready; Run it. */
		if (!dm_task_run(dmt)){
				dm_task_destroy(dmt);
                return 0;
		}

		/* Resume this dm device for changes to take effect. */
		resume_dm_device(dinfo->name);
		dm_task_destroy(dmt);
		return 1;

	}	
 	else {
		char *ttype=NULL, *ptr=NULL;
		unsigned long long start, size;
		string str,cmd;

		/* DM device does not exist. So we'll create it. */
		if(!(dmt = dm_task_create(DM_DEVICE_CREATE))){
                	cout << "in dm task create"<<endl;
	                return 0;
        	}

		/* Set properties on the new dm device */
		string prefix = "/dev/mapper/";
		string dm_disk_name = prefix + dinfo->name;
		if (!dm_task_set_name(dmt, dinfo->name)) {
			cout << "in task set name"<<endl;
			dm_task_destroy(dmt);
			return 0;
		}
		/* Making use of mkextrafs script which will create a new partition.
		 * Using this partition we'll create the dm disk on top of it.
		 */
		cout << "Creating the disk partition ..." << endl;
		prefix =  "sudo ./mkextrafs -f ";
		cmd = prefix + dinfo->mountpoint;  //This returns the newly partitioned disk name
		string disk = exec_output(cmd);           //exec_output will return the output from shell
		if (disk == "") {
			 dm_task_destroy(dmt);
                        return 0;
		}	
		cout << "Disk partition: " << disk <<endl;
		/* So we have the new partition. Find out the
		 * size of partition to create the new dm disk.
		 */
		cmd = "sudo blockdev --getsz "+disk;
		string str_size = exec_output(cmd);
		if (str_size == "") {
			dm_task_destroy(dmt);
            return 0;
		}
		
		cout << "Mapping the virtual disk " << dinfo->name << "on "<<disk<< endl; 
		/* Hardcoding all the values.
		 * Users not to worry about the geometry of the disk such as the start
		 * sector, end sector, size etc
		 */
		start = 0;
		size = strtoul(const_cast<char *>(str_size.c_str()), NULL, 0);
		ttype = dinfo->type;
		if (dinfo->parameters != NULL) {
			str = dinfo->parameters;
			str.erase(std::remove(str.begin(), str.end(), '\n'), str.end());
			string params = disk + " 0 " + str;
			params.erase(std::remove(params.begin(), params.end(), '\n'), params.end());
			ptr = const_cast<char *>(params.c_str());
			cout <<"PARAMETERS: "<<params<<endl;
		}
	
		else {
			string params = disk+" 0";
			params.erase(std::remove(params.begin(), params.end(), '\n'), params.end());
			ptr = const_cast<char *>(params.c_str());
			cout <<"PARAMETERS: "<<params<<endl;
		}

		cout <<start<<" "<<size<<" "<<ttype<<" "<<ptr<<endl;
		if (!dm_task_add_target(dmt, start, size, ttype, ptr)) {
			dm_task_destroy(dmt);
			return 0;
		}
		/* Now that we have the dm ready; Run it. */
		if (!dm_task_run(dmt)){
			cout <<"in task run"<<endl;
			dm_task_destroy(dmt);
			return 0;
		}

		sleep(1);

		str = dinfo->mountpoint;
		cmd = "sudo mount "+dm_disk_name+" "+str;
		system(const_cast<char *>(cmd.c_str()));
		cout << dinfo->name << " is mounted on " <<str <<endl;

		dm_task_destroy(dmt);
		return 1;
	}

}



/* This routine will create a device mapper(DM) device.
* It takes the arguments through the buffer and
* name specifies the name of the DM device.
*/
int create_dm_device(struct diskinfo *dinfo, char *args)
{
	struct dm_task *dmt;
	string str="";
	int r=0;

    /* Check if the required parameters for this event is supplied
     */
    if(!dinfo->command)
    {
        cerr << "Command not specified" <<endl;
        return 0;
    }

	set_disk(dinfo, args);
    /* DEBUG */
    cout <<"Event CREATE"<<endl;
    dump_diskinfos();

    if(dinfo->cmdline == NULL) {
        cout << "Cmdline is empty!" << endl;
        return 0;
    }

	/* Create a new dm device */
	if(!(dmt = dm_task_create(DM_DEVICE_CREATE))){
		cout << "in dm task create"<<endl;
		return 0;
	}

    /* Set properties on the new dm device */
	if (!dm_task_set_name(dmt, dinfo->name))
        goto out;

	/* Tokenize the command line */ 
	if(!_parse_line(dmt, dinfo->cmdline, "", 0)) {
		cout<<"in parse_line"<<endl;
		goto out;	
	}
	
	
	/* Now that we have the dm ready; Run it. */
    if (!dm_task_run(dmt)){
		cout <<"in task run"<<endl;
		goto out;
	}
        
	if (!_device_info(dinfo->name)) {
		goto out;
	}

	r=1;
	out:
       dm_task_destroy(dmt);
	   return r; 
}

/* This routine modifies the properties of a DM device.
 * The new argumenets are specified through the buffer.
 * name specifies the DM deive name.
 */
int modify_dm_device(struct diskinfo *dinfo, char *args)
{
	struct dm_task *dmt;
	int r=0;

    /* Check if the required parameters for this event is supplied
     */
    if(!dinfo->command)
    {
        cerr << "Disk type of mountpoint not specified" <<endl;
        return 0;
    }

	set_disk(dinfo, args);
    /* DEBUG */
    cout <<"Event MODIFY"<<endl;
    dump_diskinfos();


	if(dinfo->name == NULL || dinfo->cmdline == NULL) {
		cout << "Diskname or cmdline is empty!" << endl;
		return 0;
	}

    /* Create a new dm device */
    if(!(dmt = dm_task_create(DM_DEVICE_RELOAD)))
        return 0;

    /* Set properties on the new dm device */
    if (!dm_task_set_name(dmt, dinfo->name))
        goto out;

	/* Tokenize the cmdline */
    if(!_parse_line(dmt, dinfo->cmdline, "", 0))
        goto out;
    

    /* Now that we have the dm ready; Run it. */
    if (!dm_task_run(dmt))
        goto out;


    if (!_device_info(dinfo->name)) 
        goto out;
	
 
	/* Resume this dm device for changes to take effect. */
	resume_dm_device(dinfo->name);
        
	r=1;
    out:
       dm_task_destroy(dmt);
       return r;
}


/* This routine MUST be called whenever we modify properties
 * of a DM device. Once this routine returns the modified
 * properties of the DM device is made alive.
 */
int resume_dm_device(char *name)
{
	/* dmt stores all information related to the device mapper */
	struct dm_task *dmt;
	int r=0;

	/* This creates a dm device to be RESUMED */
        if (!(dmt = dm_task_create(DM_DEVICE_RESUME)))
                return 0;

	/* This sets up the name of dm device */
        if (!dm_task_set_name(dmt, name))
                goto out;

	/* This adds the dm device node */
        if (!dm_task_set_add_node(dmt, DM_ADD_NODE_ON_RESUME))
                goto out;

         /* Now that we have the dm device. Run it to make it alive. */
        if (!dm_task_run(dmt))
                goto out;

        /* DM disk is created; Query it. */
        //printf("Name: %s\n", dm_task_get_name(dmt));
        r=1;
        out:
           dm_task_destroy(dmt);
           return r;
}

/*This routine basically sets the properties specified in the buffer
 *on the device mapper disk.
 */
static int _parse_line(struct dm_task *dmt, char *buffer, const char *file,
                       int line)
{
        char ttype[LINE_SIZE], *ptr;
        unsigned long long start, size;
        int n;

        /*trim trailing space */
        for (ptr = buffer + strlen(buffer) - 1; ptr >= buffer; ptr--)
                if (!isspace((int) *ptr))
                        break;
        ptr++;
        *ptr = '\0';

        /* trim leading space */
        for (ptr = buffer; *ptr && isspace((int) *ptr); ptr++)
                ;

        if (!*ptr || *ptr == '#')
                return 1;

        if (sscanf(ptr, "%llu %llu %s %n",
                   &start, &size, ttype, &n) < 3) {
                err("Invalid format on line %d of table %s", line, file);
                return 0;
        }

        ptr += n;

        if (!dm_task_add_target(dmt, start, size, ttype, ptr))
                return 0;

        return 1;
}

/*This routine reads the file line by line and passes the line
 *to _parse_line routine to set the properties for the device
 *mapper disk.
 */
static int _parse_file(struct dm_task *dmt, const char *file)
{
        char *buffer = NULL;
        size_t buffer_size = 0;
        FILE *fp;
        int r = 0, line = 0;

        /* one-line table on cmdline */
//        if (_table)
//                return _parse_line(dmt, _table, "", ++line);

        /* OK for empty stdin */
        if (file) {
                if (!(fp = fopen(file, "r"))) {
                        err("Couldn't open '%s' for reading", file);
                        return 0;
                }
        } else
                fp = stdin;

#ifndef HAVE_GETLINE
        buffer_size = LINE_SIZE;
        if (!(buffer = (char *)dm_malloc(buffer_size))) {
                err("Failed to malloc line buffer.");
                return 0;
        }

        while (fgets(buffer, (int) buffer_size, fp))
#else
        while (getline(&buffer, &buffer_size, fp) > 0)
#endif
                if (!_parse_line(dmt, buffer, file ? : "on stdin", ++line))
                        goto out;

        r = 1;

      out:
        memset(buffer, 0, buffer_size);
#ifndef HAVE_GETLINE
        dm_free(buffer);
#else
        free(buffer);
#endif
        if (file && fclose(fp))
                fprintf(stderr, "%s: fclose failed: %s", file, strerror(errno));

        return r;
}

string exec_output(string cmd)
{
	// setup
	string data;
	FILE *stream;
	char buffer[MAX_BUFFER];

	// do it
	if (!(stream = popen(cmd.c_str(), "r"))) {
		cout << "Exec failed" << endl;
		data="";
		goto out;
	}
	while ( fgets(buffer, MAX_BUFFER, stream) != NULL )
		data.append(buffer);
	
	out:
	pclose(stream);
	return data;
}

static int _device_info(char *name)
{
	struct dm_task *dmt;
	struct dm_info info;       

	if (!(dmt = dm_task_create(DM_DEVICE_INFO)))
                return 0;

        /* Set properties on the new dm device */
        if (!dm_task_set_name(dmt, name))
                goto out;


        if (!dm_task_run(dmt))
                goto out;


        if (!dm_task_get_info(dmt, &info))
                goto out;
	
	if (info.exists)
		_display_info_long(dmt, &info);

	out:
		dm_task_destroy(dmt);
        	return info.exists ? 1 : 0;
}

static void _display_info_long(struct dm_task *dmt, struct dm_info *info)
{
        const char *uuid;
        uint32_t read_ahead;

        if (!info->exists) {
                printf("Device does not exist.\n");
                return;
        }

        printf("Name:              %s\n", dm_task_get_name(dmt));

        printf("State:             %s%s\n",
               info->suspended ? "SUSPENDED" : "ACTIVE",
               info->read_only ? " (READ-ONLY)" : "");

        /* FIXME Old value is being printed when it's being changed. */
        if (dm_task_get_read_ahead(dmt, &read_ahead))
                printf("Read Ahead:        %lu\n", read_ahead);

        if (!info->live_table && !info->inactive_table)
                printf("Tables present:    None\n");
        else
                printf("Tables present:    %s%s%s\n",
                       info->live_table ? "LIVE" : "",
                       info->live_table && info->inactive_table ? " & " : "",
                       info->inactive_table ? "INACTIVE" : "");
        if (dm_task_get_read_ahead(dmt, &read_ahead))
                printf("Read Ahead:        %lu\n", read_ahead);

        if (!info->live_table && !info->inactive_table)
                printf("Tables present:    None\n");
        else
                printf("Tables present:    %s%s%s\n",
                       info->live_table ? "LIVE" : "",
                       info->live_table && info->inactive_table ? " & " : "",
                       info->inactive_table ? "INACTIVE" : "");

        if (info->open_count != -1)
                printf("Open count:        %d\n", info->open_count);

        printf("Event number:      %lu\n", info->event_nr);
        printf("Major, minor:      %d, %d\n", info->major, info->minor);

        if (info->target_count != -1)
                printf("Number of targets: %d\n", info->target_count);

        if ((uuid = dm_task_get_uuid(dmt)) && *uuid)
                printf("UUID: %s\n", uuid);

        printf("\n");
}

int _get_device_params(const char *name)
{
        struct dm_info info;
        struct dm_task *dmt;
	uint64_t start, length;
	char *target_type, *params;

        void *next = NULL;
	int r=0;
	unsigned long long size;
	
	device_params.clear();
        if (!(dmt = dm_task_create(DM_DEVICE_TABLE)))
                return 0;

        if (!dm_task_set_name(dmt,name))
                goto out;

        if (!dm_task_run(dmt))
                goto out;

        if (!dm_task_get_info(dmt, &info) || !info.exists)
                goto out;

        do {
                next = dm_get_next_target(dmt, next, &start, &length,
                                          &target_type, &params);
                size += length;
		
		device_params.push_back(itos(start));
		device_params.push_back(itos(length));
		device_params.push_back(target_type);
		device_params.push_back(params);
	

        } while (next);

      r=1;
      out:
        dm_task_destroy(dmt);
        return r;
}

string itos(int i)	// convert int to string
{
	stringstream s;
	s << i;
	return s.str();
}

static int
parse_configfile(char *filename)
{
    FILE    *fp;
    char    buf[BUFSIZ];
	struct diskinfo *dinfo;

    assert(filename != NULL);
    assert(strlen(filename) > 0);

    if ((fp = fopen(filename, "r")) == NULL) {
        cout << "could not open configfile "<< filename <<endl;
        return -1;
    }

    while (fgets(buf, sizeof(buf), fp)) {
        int cc = strlen(buf);
        if (buf[cc-1] == '\n')
            buf[cc-1] = '\0';

		if(!strncmp(buf, "DISK", 4)) {
			char *value;
			int rc;
		
			dinfo = (struct diskinfo *) calloc(1, sizeof(*dinfo));
		
			if(!dinfo) {
				cout << "parse_configfile: out of memory" <<endl;
				goto bad;
			}

            if ((rc = event_arg_get(buf, "DISKNAME", &value)) <= 0) {
                cout << "parse_configfile: bad agent name" << endl;
                goto bad;
            }
            else if (rc >= sizeof(dinfo->name)) {
                cout << "parse_configfile: agent name is too long" << endl; 
                goto bad;
            }
            strncpy(dinfo->name, value, rc);
            dinfo->name[rc] = '\0';

            if ((rc = event_arg_dup(buf, "DISKTYPE", &dinfo->type)) == 0) {
            	free(dinfo->type);
				dinfo->type = NULL;			    
            }
			dinfo->initial_type = dinfo->type;			

            if ((rc = event_arg_dup(buf, "MOUNTPOINT", &dinfo->mountpoint)) == 0) {
                free(dinfo->mountpoint);
                dinfo->mountpoint = NULL;
            }
			dinfo->initial_mountpoint = dinfo->mountpoint;
		
            if ((rc = event_arg_dup(buf, "PARAMETERS", &dinfo->parameters)) == 0) {
                free(dinfo->parameters);
                dinfo->parameters = NULL;
            }
			dinfo->initial_parameters = dinfo->parameters;
			
            if ((rc = event_arg_dup(buf, "COMMAND", &dinfo->cmdline)) == 0) {
				free(dinfo->cmdline);
				dinfo->cmdline = NULL;
            }
			dinfo->initial_cmdline = dinfo->cmdline;			

			dinfo->next = diskinfos;
			diskinfos   = dinfo;
			continue;
		}
	}
    fclose(fp);
    return 0;
bad:
	fclose(fp);
	return -1;		
}		
		
static void
set_disk(struct diskinfo *dinfo, char *args)
{
    assert(dinfo != NULL);
    assert(args != NULL);

	cout << "Args in set_disk " << args << endl;
    /*
     * The args string holds the command line to execute. We allow
     * this to be reset in dynamic events, but is optional; the cuurent
     * command will be used by default, which initially comes from tmcd.
     */
    if (args && (strlen(args) > 0)) {
        char *value;
        int rc;

        /*
         * COMMAND is special. For backward compat it can contain
         * whitespace but need not be quoted.  In fact, if the string
         * is quoted, we just pass the quotes through to the program.
         */
        if ((rc = event_arg_get(args, "COMMAND", &value)) > 0) {
            cout <<"COMMAND "<<value<<endl;
			if (dinfo->cmdline != NULL) {
                if (dinfo->cmdline != dinfo->initial_cmdline) {
                    free(dinfo->cmdline);
                    dinfo->cmdline = NULL;
                }
            }
            /*
             * XXX event_arg_get will return a pointer beyond
             * any initial quote character.  We need to back the
             * pointer up if that is the case.
             */
            if (value[-1] == '\'' || value[-1] == '{')
                value--;
            asprintf(&dinfo->cmdline, "%s", value);
            value = NULL;
        }
        if ((rc = event_arg_dup(args, "DISKTYPE", &value)) >= 0) {
			cout << "DISKTYPE "<<value<<endl;
            if (dinfo->type != NULL) {
                if (dinfo->type != dinfo->initial_type)
                    free(dinfo->type);
            }
			if(rc == 0) {
				dinfo->type = NULL;
				free(value);
			}
			else if (rc > 0) {
				dinfo->type = value;
			}
			else {
				assert(0);
			}
			value = NULL;
		}
        if ((rc = event_arg_dup(args, "MOUNTPOINT", &value)) >= 0) {
            if (dinfo->mountpoint != NULL) {
                if (dinfo->mountpoint != dinfo->initial_mountpoint)
                    free(dinfo->mountpoint);
            }
            if(rc == 0) {
                dinfo->mountpoint = NULL;
                free(value);
            }
            else if (rc > 0) {
                dinfo->mountpoint = value;
            }
            else {
                assert(0);
            }
            value = NULL;
        }
        if ((rc = event_arg_dup(args, "PARAMETERS", &value)) >= 0) {
			cout << "TYPE "<<value<<endl;
            if (dinfo->parameters != NULL) {
                if (dinfo->parameters != dinfo->initial_parameters)
                    free(dinfo->parameters);
            }
            if(rc == 0) {
                dinfo->parameters = NULL;
                free(value);
            }
            else if (rc > 0) {
                dinfo->parameters = value;
            }
            else {
                assert(0);
            }
            value = NULL;
        }				
		
	}
}


static void
start_callback(event_handle_t handle,
           event_notification_t notification,
           void *data)
{
    char        event[TBDB_FLEN_EVEVENTTYPE];

    assert(handle != NULL);
    assert(notification != NULL);
    assert(data == NULL);

    if (! event_notification_get_eventtype(handle, notification,
                           event, sizeof(event))) {
        cerr << "Could not get event from notification!\n" << endl;
        return;
    }

    if (strcmp(event, TBDB_EVENTTYPE_START) == 0) {
        struct diskinfo *dinfo;

        for (dinfo = diskinfos; dinfo != NULL; dinfo = dinfo->next) {

            if (dinfo->cmdline != dinfo->initial_cmdline) {
                free(dinfo->cmdline);
                dinfo->cmdline = dinfo->initial_cmdline;
            }
            if (dinfo->type != dinfo->initial_type) {
                free(dinfo->type);
                dinfo->type = dinfo->initial_type;
            }
            if (dinfo->mountpoint != dinfo->initial_mountpoint) {
                free(dinfo->mountpoint);
                dinfo->mountpoint = dinfo->initial_mountpoint;
            }
            if (dinfo->parameters != dinfo->initial_parameters) {
                free(dinfo->parameters);
                dinfo->parameters = dinfo->initial_parameters;
            }

        }
	}
}

	
