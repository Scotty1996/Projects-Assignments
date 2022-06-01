CREATE DATABASE  IF NOT EXISTS `assignment4mysql` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `assignment4mysql`;
-- MySQL dump 10.13  Distrib 8.0.28, for Win64 (x86_64)
--
-- Host: localhost    Database: assignment4mysql
-- ------------------------------------------------------
-- Server version	8.0.28

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `course`
--

DROP TABLE IF EXISTS `course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course` (
  `idcourse` int NOT NULL,
  `courseName` varchar(45) DEFAULT NULL,
  `enrollNo` int DEFAULT NULL,
  PRIMARY KEY (`idcourse`),
  KEY `FK_course_enrolledNo` (`enrollNo`),
  CONSTRAINT `FK_course_enrolledNo` FOREIGN KEY (`enrollNo`) REFERENCES `student` (`idstudent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `course`
--

LOCK TABLES `course` WRITE;
/*!40000 ALTER TABLE `course` DISABLE KEYS */;
INSERT INTO `course` VALUES (1,'Mathematics',1),(2,'Science',1),(3,'Geograhy',1);
/*!40000 ALTER TABLE `course` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hod`
--

DROP TABLE IF EXISTS `hod`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hod` (
  `idhod` int NOT NULL,
  `pwd` varchar(45) DEFAULT NULL,
  `courseNo` int DEFAULT NULL,
  `InstructorNo` int DEFAULT NULL,
  PRIMARY KEY (`idhod`),
  KEY `FK_hod_courseNo` (`courseNo`),
  KEY `FK_hod_instructorNo` (`InstructorNo`),
  CONSTRAINT `FK_hod_courseNo` FOREIGN KEY (`courseNo`) REFERENCES `course` (`idcourse`),
  CONSTRAINT `FK_hod_instructorNo` FOREIGN KEY (`InstructorNo`) REFERENCES `teacher` (`idteacher`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hod`
--

LOCK TABLES `hod` WRITE;
/*!40000 ALTER TABLE `hod` DISABLE KEYS */;
INSERT INTO `hod` VALUES (1,'hod1',NULL,NULL),(2,'hod2',NULL,NULL),(3,'hod3',NULL,NULL);
/*!40000 ALTER TABLE `hod` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `student`
--

DROP TABLE IF EXISTS `student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student` (
  `idstudent` int NOT NULL,
  `pwd` varchar(45) DEFAULT NULL,
  `quiz1` int DEFAULT NULL,
  `quiz2` int DEFAULT NULL,
  `assignment1` int DEFAULT NULL,
  `assignment2` int DEFAULT NULL,
  `assignment3` int DEFAULT NULL,
  `mid` int DEFAULT NULL,
  `final` int DEFAULT NULL,
  `total` int DEFAULT NULL,
  `courseNo` int DEFAULT NULL,
  PRIMARY KEY (`idstudent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student`
--

LOCK TABLES `student` WRITE;
/*!40000 ALTER TABLE `student` DISABLE KEYS */;
INSERT INTO `student` VALUES (1,'student1',50,50,100,100,100,50,100,80,1),(2,'student2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,2),(3,'student3',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,3);
/*!40000 ALTER TABLE `student` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher`
--

DROP TABLE IF EXISTS `teacher`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher` (
  `idteacher` int NOT NULL,
  `pwd` varchar(45) DEFAULT NULL,
  `pupilNo` int DEFAULT NULL,
  `courseNo` int DEFAULT NULL,
  PRIMARY KEY (`idteacher`),
  KEY `FK_teacher_pupil` (`pupilNo`),
  KEY `FK_teacher_courseNo` (`courseNo`),
  CONSTRAINT `FK_teacher_courseNo` FOREIGN KEY (`courseNo`) REFERENCES `course` (`idcourse`),
  CONSTRAINT `FK_teacher_pupil` FOREIGN KEY (`pupilNo`) REFERENCES `student` (`idstudent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher`
--

LOCK TABLES `teacher` WRITE;
/*!40000 ALTER TABLE `teacher` DISABLE KEYS */;
INSERT INTO `teacher` VALUES (1,'teacher1',1,1),(2,'teacher2',1,2),(3,'teacher3',1,3);
/*!40000 ALTER TABLE `teacher` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-04-08 20:39:14
