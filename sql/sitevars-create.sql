-- MySQL dump 8.23
--
-- Host: localhost    Database: tbdb
---------------------------------------------------------
-- Server version	3.23.58-log

--
-- Dumping data for table `sitevariables`
--


INSERT INTO sitevariables VALUES ('general/testvar',NULL,'43','A test variable');
INSERT INTO sitevariables VALUES ('web/nologins',NULL,'0','Non-zero value indicates that no non-admin user may log into the Web Interface.');
INSERT INTO sitevariables VALUES ('web/message',NULL,'','Message to place in large lettering under the login message on the Web Interface.');
INSERT INTO sitevariables VALUES ('idle/threshold',NULL,'4','Number of hours of inactivity for a node/expt to be considered idle.');
INSERT INTO sitevariables VALUES ('idle/mailinterval',NULL,'4','Number of hours since sending a swap request before sending another one. (Timing of first one is determined by idle/threshold.)');
INSERT INTO sitevariables VALUES ('idle/cc_grp_ldrs',NULL,'3','Start CC\'ing group and project leaders on idle messages on the Nth message.');
INSERT INTO sitevariables VALUES ('batch/retry_wait',NULL,'900','Number of seconds to wait before retrying a failed batch experiment.');
INSERT INTO sitevariables VALUES ('swap/idleswap_warn',NULL,'30','Number of minutes before an Idle-Swap to send a warning message. Set to 0 for no warning.');
INSERT INTO sitevariables VALUES ('swap/autoswap_warn',NULL,'60','Number of minutes before an Auto-Swap to send a warning message. Set to 0 for no warning.');
INSERT INTO sitevariables VALUES ('idle/batch_threshold',NULL,'30','Number of minutes of inactivity for a batch node/expt to be considered idle.');
INSERT INTO sitevariables VALUES ('general/recently_active',NULL,'14','Number of days to be considered a recently active user of the testbed.');
INSERT INTO sitevariables VALUES ('plab/load_metric',NULL,'load_fifteen','GMOND load metric to use (load_one, load_five, load_fifteen)');
INSERT INTO sitevariables VALUES ('plab/max_load',NULL,'5.0','Load at which to stop admitting jobs (0==admit nothing, 1000==admit all)');
INSERT INTO sitevariables VALUES ('plab/min_disk',NULL,'10.0','Minimum disk space free at which to stop admitting jobs (0==admit all, 100==admit none)');
INSERT INTO sitevariables VALUES ('plab/stale_age',NULL,'60','Age in minutes at which to consider site data stale and thus node down (0==always use data)');
INSERT INTO sitevariables VALUES ('watchdog/interval',NULL,'60','Interval in minutes between checks for changes in timeout values (0==never check)');
INSERT INTO sitevariables VALUES ('watchdog/ntpdrift',NULL,'240','Interval in minutes between reporting back NTP drift changes (0==never report)');
INSERT INTO sitevariables VALUES ('watchdog/cvsup',NULL,'720','Interval in minutes between remote node checks for software updates (0==never check)');
INSERT INTO sitevariables VALUES ('watchdog/isalive/local',NULL,'3','Interval in minutes between local node status reports (0==never report)');
INSERT INTO sitevariables VALUES ('watchdog/isalive/vnode',NULL,'10','Interval in minutes between virtual node status reports (0==never report)');
INSERT INTO sitevariables VALUES ('watchdog/isalive/plab',NULL,'10','Interval in minutes between planetlab node status reports (0==never report)');
INSERT INTO sitevariables VALUES ('watchdog/isalive/wa',NULL,'1','Interval in minutes between widearea node status reports (0==never report)');
INSERT INTO sitevariables VALUES ('watchdog/isalive/dead_time',NULL,'120','Time, in minutes, after which to consider a node dead if it has not checked in via tha watchdog');
INSERT INTO sitevariables VALUES ('watchdog/rusage',NULL,'1','Interval in minutes between node resource usage reports (0==never report)');
INSERT INTO sitevariables VALUES ('plab/setup/vnode_batch_size',NULL,'40','Number of plab nodes to setup simultaneously');
INSERT INTO sitevariables VALUES ('plab/setup/vnode_wait_time',NULL,'960','Number of seconds to wait for a plab node to setup');
