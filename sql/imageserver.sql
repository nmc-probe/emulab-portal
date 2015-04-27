-- MySQL dump 10.10
--
-- Host: localhost    Database: tbdb
-- ------------------------------------------------------
-- Server version	5.0.20-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

DROP TABLE IF EXISTS `image_versions`;
CREATE TABLE `image_versions` (
  `imagename` varchar(30) NOT NULL default '',
  `version` int(8) unsigned NOT NULL default '0',
  `imageid` int(8) unsigned NOT NULL default '0',
  `version_uuid` varchar(40) NOT NULL default '',
  `creator` varchar(8) default NULL,
  `creator_urn` varchar(128) default NULL,
  `created` datetime default NULL,
  `description` tinytext NOT NULL,
  `os_type` varchar(32) NOT NULL default '',
  `os_version` varchar(12) default '',
  `os_features` mediumtext defaut '',
  `mbr_version` varchar(50) NOT NULL default '1',
  `metadata_url` tinytext,
  `imagefile_url` tinytext,
  `isdataset` tinyint(1) NOT NULL default '0',
  `nodetypes` text default NULL,
  `bitsize` enum ('32','64') NOT NULL default '32',
  `arch` enum ('x86','arm64') NOT NULL default 'x86',
  PRIMARY KEY  (`imageid`,`version`),
  UNIQUE KEY `uuid` (`uuid`),
  FULLTEXT KEY `imagesearch` (`imagename`,`description`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `images`
--

DROP TABLE IF EXISTS `images`;
CREATE TABLE `images` (
  `imagename` varchar(30) NOT NULL default '',
  `imageid` int(8) unsigned NOT NULL default '0',
  `version` int(8) unsigned NOT NULL default '0',
  `aggregate_urn` varchar(128) default NULL,
  `image_urn` varchar(128) default NULL,
  `pid` varchar(48) NOT NULL default '',
  `gid` varchar(32) NOT NULL default '',
  `uuid` varchar(40) NOT NULL default '',
  `locked` datetime default NULL,
  `locker_pid` int(11) default '0',
  PRIMARY KEY  (`imageid`),
  UNIQUE KEY `uuid` (`uuid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
