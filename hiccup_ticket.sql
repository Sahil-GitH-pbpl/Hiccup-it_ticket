-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 07, 2026 at 02:07 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hiccup_ticket`
--

-- --------------------------------------------------------

--
-- Table structure for table `department_master`
--

CREATE TABLE `department_master` (
  `id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hiccups`
--

CREATE TABLE `hiccups` (
  `hiccup_id` int(11) NOT NULL,
  `raised_by` int(11) DEFAULT NULL,
  `raised_by_department` int(11) DEFAULT NULL,
  `hiccup_type` enum('Person Related','System Related') DEFAULT NULL,
  `raised_against` int(11) DEFAULT NULL,
  `raised_against_department` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `immediate_effect` text DEFAULT NULL,
  `attachment_path` varchar(500) DEFAULT NULL,
  `response_by` int(11) DEFAULT NULL,
  `response_text` text DEFAULT NULL,
  `status` enum('Open','Responded','Under Review','Closed','Escalated to NC') DEFAULT 'Open',
  `escalated_by` int(11) DEFAULT NULL,
  `root_cause` text DEFAULT NULL,
  `corrective_action` text DEFAULT NULL,
  `closure_notes` text DEFAULT NULL,
  `closed_at` timestamp NULL DEFAULT NULL,
  `is_auto_generated` tinyint(1) DEFAULT 0,
  `source_module` varchar(100) DEFAULT NULL,
  `confidential_flag` tinyint(1) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `followup_status` enum('Pending','Resolved','Unresolved') DEFAULT 'Pending',
  `followup_comment` text DEFAULT NULL,
  `root_cause_category` enum('Training Need','Process Gap','Negligence','System Error','External Factor','Resource Shortage') DEFAULT NULL,
  `is_response_overdue` tinyint(1) DEFAULT 0,
  `is_closure_overdue` tinyint(1) DEFAULT 0,
  `raised_by_name` varchar(255) DEFAULT NULL,
  `raised_against_name` varchar(255) DEFAULT NULL,
  `response_by_name` varchar(255) DEFAULT NULL,
  `raised_against_department_name` varchar(255) DEFAULT NULL,
  `response_blocked` tinyint(1) DEFAULT 0,
  `reminder_sent` tinyint(1) DEFAULT 0,
  `overdue_msg_sent` tinyint(1) DEFAULT 0,
  `escalate_msg_sent` tinyint(1) DEFAULT 0,
  `nc_assigned_staff_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hiccup_audit_log`
--

CREATE TABLE `hiccup_audit_log` (
  `log_id` int(11) NOT NULL,
  `hiccup_id` int(11) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `performed_by` int(11) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT NULL,
  `remarks` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `infra_tickets`
--

CREATE TABLE `infra_tickets` (
  `ticket_id` int(11) NOT NULL,
  `created_by` int(11) DEFAULT NULL,
  `department` int(11) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `subcategory` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `workstation` varchar(100) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `assigned_to` int(11) DEFAULT NULL,
  `commitment_time` timestamp NULL DEFAULT NULL,
  `is_delayed_pick` tinyint(1) DEFAULT 0,
  `is_invalid` tinyint(1) DEFAULT 0,
  `invalid_reason` text DEFAULT NULL,
  `image_path` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `reminder_sent` tinyint(1) DEFAULT 0,
  `contact` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `infra_ticket_images`
--

CREATE TABLE `infra_ticket_images` (
  `image_id` int(11) NOT NULL,
  `ticket_id` int(11) DEFAULT NULL,
  `image_path` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `infra_updates`
--

CREATE TABLE `infra_updates` (
  `update_id` int(11) NOT NULL,
  `ticket_id` int(11) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nc_escalation_forms`
--

CREATE TABLE `nc_escalation_forms` (
  `id` int(11) NOT NULL,
  `hiccup_id` int(11) DEFAULT NULL,
  `staff_name` varchar(255) DEFAULT NULL,
  `issue_description` text DEFAULT NULL,
  `root_cause_flags` varchar(500) DEFAULT NULL,
  `root_cause_explanation` text DEFAULT NULL,
  `corrective_action` text DEFAULT NULL,
  `corrective_action_by` varchar(255) DEFAULT NULL,
  `corrective_action_date` date DEFAULT NULL,
  `person_responsible` varchar(255) DEFAULT NULL,
  `timeline_for_completion` varchar(255) DEFAULT NULL,
  `followup_review` text DEFAULT NULL,
  `preventive_actions` varchar(500) DEFAULT NULL,
  `preventive_details` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `root_cause_other` text DEFAULT NULL,
  `preventive_other` text DEFAULT NULL,
  `assigned_staff_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `contact` varchar(20) NOT NULL,
  `departments` varchar(50) DEFAULT NULL,
  `role` varchar(50) NOT NULL DEFAULT 'staff_user',
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dob` varchar(10) DEFAULT NULL,
  `designation` varchar(100) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `password`, `contact`, `departments`, `role`, `status`, `last_updated`, `dob`, `designation`, `department_id`) VALUES
(1, 'MD ARIF SAIFI', 'PBPL00422', '8586873925', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '14/04/2000', 'Admin', NULL),
(2, 'Rohit Kumar Pandey', 'PBPL00112', '9598226263', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/07/1993', 'Admin', NULL),
(3, 'Vivek kumar Tiwari', 'PBPL00174', '7531031254', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/06/1997', 'Admin', NULL),
(4, 'Namrita yadav', 'PBPL00513', '8882358029', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '09/12/2004', 'Customer Care', NULL),
(5, 'Mashroor khan', 'PBPL00529', '8527201519', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/03/1997', 'Customer Care', NULL),
(6, 'Sanjeet Kumar', 'PBPL00197', '7982256085', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '24/12/1987', 'Customer Care', NULL),
(7, 'Ritu Mahalwal', 'PBPL 00312', '9871366002', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '25/03/1985', 'Customer Care', NULL),
(8, 'RAHNUMA KHATOON', 'PBPL00104', '8573929263', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/06/1994', 'Admin', NULL),
(9, 'Manisha', 'PBPL00561', '7042308798', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '04/10/1999', 'Customer Care', NULL),
(10, 'Sushil Kumar', 'PBPL00208', '9717852423', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/02/1991', 'Center Phlebo', NULL),
(11, 'Sumit Sirishwal', 'Pbpl000387', '8448010951', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '29/06/1998', 'Customer Care', NULL),
(12, 'KIRAN MANRAL', 'PBPL00500', '8392819642', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '08/04/1998', 'Center Phlebo', NULL),
(13, 'GIRDHAR SINGH BORA', 'PBPL00590', '9971381045', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/09/1996', 'Technical', NULL),
(14, 'Firoz Saifi', 'PBPL00569', '7827967669', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '22/05/1994', 'Home Collection Phlebo', NULL),
(15, 'Himani Rawat', 'PBPL006027', '9990226100', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '29/09/2005', 'Technical', NULL),
(16, 'SAMI AHMAD KHAN', 'PBPL00409', '7520132030', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '17/09/2003', 'Technical', NULL),
(17, 'Aman Shukla', 'PBPL00382', '8178408980', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/03/2002', 'Field', NULL),
(18, 'Ravi Chaudhary', 'PBPL00204', '9811005760', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '14/10/1990', 'Technical', NULL),
(19, 'Roopa Rani', 'PBPL00353', '9915932746', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '21/08/1994', 'Center Phlebo', NULL),
(20, 'SUMIT SINGH', 'PBPL00502', '9821957370', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '05/01/1997', 'Home Collection Phlebo', NULL),
(21, 'Neeraj kumar', 'PBPL00190', '7503711127', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/2002', 'Field', NULL),
(22, 'Kailash', 'PBBL0000134', '9810375490', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '12/03/1996', 'Field', NULL),
(23, 'Keshav', 'PBBL00415', '9871860499', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '11/05/1998', 'Field', NULL),
(24, 'Aman Ahmed', 'PBPL00411', '7827865007', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '21/07/2001', 'Field', NULL),
(25, 'Jyoti sakya', 'PBPL00524', '9718879504', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/04/1998', 'Center Phlebo', NULL),
(26, 'Khemchand', 'PBPL00175', '9953699384', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '03/09/1989', 'Field', NULL),
(27, 'Gulrez Sultan', 'PBPL00556', '9818247844', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/02/1985', 'Customer Care', NULL),
(28, 'SHIV KUMAR', 'PBPL 00130', '9643658494', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '03/05/1988', 'Field', NULL),
(29, 'Priyanka Raikwar', 'PBPL00207', '8447623749', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '21/10/1985', 'Admin', NULL),
(30, 'Rahul Sharma', 'PBPL006014', '7701967897', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '23/01/1996', 'Field', NULL),
(31, 'Mohit kumar', 'PBPL00341', '9773568276', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/07/2001', 'Field', NULL),
(32, 'ADNAN KHAN', 'PBPL00633', '6396202648', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '26/07/2002', 'Technical', NULL),
(33, 'Megha', 'PBPL 00559', '8810356910', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '27/04/1996', 'Customer Care', NULL),
(34, 'Razmi kamal', 'PBPL00184', '8586996357', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '12/05/1967', 'Field', NULL),
(35, 'Shahana Parveen', 'PBPL00176', '8448546358', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/07/1995', 'Marketing', NULL),
(36, 'Anshu kumari', 'PBPL006020', '8920619900', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '28/05/2003', 'Technical', NULL),
(37, 'Abhimanyu Singh', 'PBPL00106', '9971406089', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '11/02/1993', 'Marketing', NULL),
(38, 'Moinul hasan', 'Pbpl00605', '9310937653', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '02/05/2000', 'Home Collection Phlebo', NULL),
(39, 'DEEPAK SENGAR', 'PBPL00475', '8810428595', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '01/07/1996', 'Field', NULL),
(40, 'Gunjan mehta', 'PBPL-00439', '9810312510', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '12/03/1983', 'Marketing', NULL),
(41, 'Ritesh Kumar', 'PBPL00171', '9695983021', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '06/08/1993', 'Admin', NULL),
(42, 'Kanak lata Pallai', 'PBPL00168', '9910240993', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '24/04/1980', 'Technical', NULL),
(43, 'Arti', 'PBPL00431', '7065467760', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '15/09/1999', 'Center Phlebo', NULL),
(44, 'AKASH', 'PBPL00517', '8755346358', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '25/03/2002', 'Center Phlebo', NULL),
(45, 'Dipanshi', 'PBPL006012', '8527343704', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/01/2003', 'Technical', NULL),
(46, 'SHAHBAZ MOHSIN', 'PBPL00558', '7982379071', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/02/1985', 'Center Phlebo', NULL),
(47, 'Kanchana Manral', 'PBPL00444', '8650299233', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/06/2002', 'Technical', NULL),
(48, 'Manish', 'PBPL006046', '8130861621', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '11/09/1996', 'Field', NULL),
(49, 'Rajeev kumar', 'PBPL00154', '7210004748', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '06/08/2000', 'Field', NULL),
(50, 'Mohd aftab alam', 'PBPL006052', '8468957851', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '20/01/1995', 'Center Phlebo', NULL),
(51, 'Mahendra pal', 'PBPL00390', '9625756762', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/02/1998', 'Home Collection Phlebo', NULL),
(52, 'SAHIL BISHT', 'PBPL006029', '8057054076', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/02/2002', 'Admin', NULL),
(53, 'KARAN JHA', 'PBPL00170', '7678489842', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '08/07/1996', 'Admin', NULL),
(54, 'Zeenat', 'PBPL00541', '8920707932', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/10/2001', 'Center Phlebo', NULL),
(55, 'Rohit Kumar', 'PBL006030', '8808290797', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '20/01/1997', 'House Keeping', NULL),
(56, 'Asha', 'PBPL000317', '9625993539', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/03/2000', 'Center Phlebo', NULL),
(57, 'Ritu Rawat', 'PBPL006023', '8130256945', '2', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '04/10/1995', 'House Keeping', NULL),
(58, 'Sachin', 'PBPL00510', '8441890010', '2', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '04/03/2002', 'House Keeping', NULL),
(59, 'Md Shaquib Alam', 'PBPL00520', '8448558464', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/07/1998', 'Technical', NULL),
(60, 'VIMAL RANJAN PANDEY', 'PBPL00198', '8826140791', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '25/07/1993', 'Technical', NULL),
(61, 'MOHD AARISH', 'PBPL00485', '9315144233', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '22/09/1999', 'Center Phlebo', NULL),
(62, 'Jyoti Marwah', 'PBPL00504', '9821189006', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '27/08/1991', 'Technical', NULL),
(63, 'AMAN CHOTALA', 'pbpl00229', '9773552558', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '28/06/1999', 'Customer Care', NULL),
(64, 'Imran Ansari', 'Pbpl00373', '7277209636', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/01/2001', 'Technical', NULL),
(65, 'MOHD KARAM ALI', 'PBPL00173', '8383036512', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/1988', 'Center Phlebo', NULL),
(66, 'Ravi Kumar Pandey', 'PBPL000463', '9565438695', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/07/2003', 'Technical', NULL),
(67, 'Beena Bisht', 'PBPL00432', '9999123130', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '08/10/1991', 'Technical', NULL),
(68, 'Harshita Basnuwal', 'PBPL00434', '8505916252', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '24/02/2002', 'Technical', NULL),
(69, 'Mohd moin husain', 'PBPL006045', '6392969672', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/07/2005', 'Customer Care', NULL),
(70, 'Binita Devi', 'PBPL00578', '8506854833', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/1987', 'House Keeping', NULL),
(71, 'Mukesh', 'PBPL006017', '7982506422', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/08/1984', 'Home Collection Phlebo', NULL),
(72, 'Samreen Mirza', 'PBPL06018', '8448338630', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '22/02/2002', 'Center Phlebo', NULL),
(73, 'Komal', 'PBPL00507', '8920977782', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/11/1998', 'Center Phlebo', NULL),
(74, 'Azeem Ahmed', 'PBPL00231', '9911994840', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '18/12/1995', 'Home Collection Phlebo', NULL),
(75, 'Ragini', 'PBPL006075', '9205031246', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '03/09/1999', 'Center Phlebo', NULL),
(76, 'SABBO', 'PBPL006007', '9310503665', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/01/2000', 'Center Phlebo', NULL),
(77, 'Jaspal singh rawat', 'PBPL006035', '7838686369', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '19/08/1994', 'Customer Care', NULL),
(78, 'Vishal', 'PBPL00530', '7015352509', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '27/10/1998', 'Center Phlebo', NULL),
(79, 'Sabbir', 'PBPL00531', '7217660742', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '19/09/2002', 'Center Phlebo', NULL),
(80, 'Atish', 'PBPL00535', '9310388376', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '07/04/2003', 'Center Phlebo', NULL),
(81, 'Shashi Bhushan Kumar', 'PBPL00113', '9315844775', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/04/1982', 'Home Collection Phlebo', NULL),
(82, 'Uday Pratap Yadav', 'PBPL006038', '9140006961', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/12/1998', 'Admin', NULL),
(83, 'Abhishek Chauhan', 'PBPL00116', '9717009238', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '29/08/2000', 'Center Phlebo', NULL),
(84, 'SUJATA LILHARE', 'PBPLP00381', '9552928353', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '14/10/2000', 'Center Phlebo', NULL),
(85, 'SALEEM JAVED', 'PBPL00212', '9654441851', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '17/07/1973', 'Customer Care', NULL),
(86, 'Vishvender', 'PBPL00332', '8700965931', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/03/1995', 'Home Collection Phlebo', NULL),
(87, 'Vandana', 'PBPL00413', '8076585534', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '05/07/2003', 'Center Phlebo', NULL),
(88, 'Mohd gayas alam', 'PBPL00318', '9058860807', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '08/07/2001', 'Home Collection Phlebo', NULL),
(89, 'PUSHPENDER', 'PBPLl00423', '9910474470', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/05/1999', 'Home Collection Phlebo', NULL),
(90, 'Aashu kashyap', 'PBPL00584', '6203999124', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '23/05/2000', 'Admin', NULL),
(91, 'A . Sylvia', 'PBPL00441', '8838592205', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '17/02/1998', 'Technical', NULL),
(92, 'Mohammad Waseem', 'PBPL00555', '7065718317', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '04/01/1997', 'Technical', NULL),
(93, 'Rupa', 'PBPL00452', '9582878288', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '03/07/1993', 'Center Phlebo', NULL),
(94, 'Sarika', 'PBPL006011', '9899414239', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '12/04/2004', 'Technical', NULL),
(95, 'ANKITA', 'PBPL00188', '8700004157', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/02/2002', 'Customer Care', NULL),
(96, 'Sujeet kumar', 'PBPL00514', '8375038528', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '04/01/2001', 'Center Phlebo', NULL),
(97, 'Maria Dass', 'PBPL00177', '9654876714', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/06/1977', 'Customer Care', NULL),
(98, 'Neeraj Kumar Mandal', 'PBPL00247', '7011876467', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '17/01/2001', 'Center Phlebo', NULL),
(99, 'Prerna', 'PBPL00505', '8826879686', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '11/10/2001', 'Technical', NULL),
(100, 'Anshuman kumar', 'PBPL00585', '9155817760', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '05/07/1998', 'Technical', NULL),
(101, 'Mehrab alam', 'PBPL00523', '9891952645', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '21/09/1997', 'Home Collection Phlebo', NULL),
(102, 'Ram bharosha', 'PBPL006048', '7827479365', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '02/07/1998', 'Field', NULL),
(103, 'Vandana Maurya', 'PBPL00465', '8299806719', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '20/10/1999', 'Center Phlebo', NULL),
(104, 'DHANBIR SINGH RAWAT', 'PBPL00139', '7291848485', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '12/11/1972', 'Marketing', NULL),
(105, 'Shagun', 'PBPL00451', '9318474986', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '11/11/2000', 'Technical', NULL),
(106, 'Akshay Kumar Ram', 'PBPL00562', '9958547534', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '31/03/1998', 'House Keeping', NULL),
(107, 'Yash Sharma', 'PBPL00488', '8800953795', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '04/03/2005', 'House Keeping', NULL),
(108, 'Reena Khandelwal', 'PBPL006034', '8585993878', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '02/07/1986', 'Admin', NULL),
(109, 'Suresh Kundra', 'PBPL006056', '9667798385', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '06/02/1981', 'Customer Care', NULL),
(110, 'Natthu Ram', 'PBPL006042', '9821942388', '2', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '01/01/1980', 'House Keeping', NULL),
(111, 'Saurabh Singh Negi', 'PBPL006063', '7078152416', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '26/09/2003', 'Center Phlebo', NULL),
(112, 'Payal Joshi', 'PBPL006061', '8077832960', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '05/03/2002', 'Technical', NULL),
(113, 'Manwar Singh negi', 'PBPL006057', '9540071850', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '26/08/2002', 'Technical', NULL),
(114, 'Maahi Tiwari', 'PBPL006053', '7678169861', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '22/12/2004', 'Center Phlebo', NULL),
(115, 'Rokhsar Bano', 'PBPL006065', '9315170745', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/02/2003', 'Center Phlebo', NULL),
(116, 'Anuj kumar choudhary', 'PBPL006069', '9625882897', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '03/04/2005', 'Customer Care', NULL),
(117, 'Anisha', 'PBPL006077', '9310058512', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '03/01/2005', 'Center Phlebo', NULL),
(118, 'Riya Agrahari', 'PBPL006081', '8924848255', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '17/07/2002', 'Center Phlebo', NULL),
(119, 'Chitrisha Tiwari', 'PBPL006071', '9311013305', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '24/09/2002', 'Technical', NULL),
(120, 'Md Kalim', 'PBPL006085', '7550425998', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '04/01/1998', 'Home Collection Phlebo', NULL),
(121, 'Surendra pal mahur', 'Pbploo6091', '9810666534', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/05/1978', 'Home Collection Phlebo', NULL),
(122, 'Mahavir Singh Rawat', 'PBPl006086', '9871723521', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '18/09/1974', 'Marketing', NULL),
(123, 'HARENDRA KUMAR', 'PBPL006087', '9958213380', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '22/06/1988', 'Home Collection Phlebo', NULL),
(124, 'Dr Vishu Bhasin', 'Pbpl', '9810637037', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '24/03/1985', 'Admin', NULL),
(125, 'Dr Vipul Bhasin', 'PBPL', '9810030372', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '21/03/1991', 'Admin', NULL),
(126, 'Dr Nitika Aggarwal', 'PBPL', '9311513399', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '08/07/1978', 'Technical', NULL),
(127, 'Dr.Shashikant Singh', 'PBPL', '9540748692', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '28/05/1989', 'Technical', NULL),
(128, 'Prakash Kumar', 'PBPL006070', '9811081575', '2', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '22/09/1977', 'House Keeping', NULL),
(129, 'Sunny', 'PBPL006062', '9811302806', '2', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '24/10/1998', 'House Keeping', NULL),
(130, 'Rakesh Kumar', 'PBPL006068', '9987579418', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '12/08/1990', 'Admin', NULL),
(131, 'Rahul Kumar', 'PBPL006093', '9798895779', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '08/02/2002', 'Technical', NULL),
(132, 'Md Adnan', 'Pbpl006102', '9205956716', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '27/11/2001', 'Home Collection Phlebo', NULL),
(133, 'Harshit', 'PBPL006103', '9310305734', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '26/11/2002', 'Technical', NULL),
(134, 'Bushra khan', 'PBPL006098', '7678617229', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '19/08/2001', 'Technical', NULL),
(135, 'Arvind', 'PBPL006092', '9311270502', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/1998', 'House Keeping', NULL),
(136, 'Satyam kumar', 'PBPL006088', '8595422758', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '28/09/2000', 'Field', NULL),
(137, 'Akash yadav', 'Pbpl006109', '9899847571', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '08/07/2000', 'Customer Care', NULL),
(138, 'Aditya Upadhyay', 'PBPL006110', '6394138497', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '07/04/2004', 'Technical', NULL),
(139, 'Shalini rawat', 'PBPL006107', '9650692437', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/2002', 'Customer Care', NULL),
(140, 'Simran', 'PBPL006108', '8368069817', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/01/2007', 'Admin', NULL),
(141, 'Harsh', 'PBPL006105', '9643447688', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '25/08/2002', 'Field', NULL),
(142, 'Vishakha', 'PBPL006115', '9818924188', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '14/02/2005', 'Center Phlebo', NULL),
(143, 'Saurav kumar', 'PBPL006116', '7428679875', '1,6,5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '01/01/2004', 'Technical', NULL),
(144, 'Mona', 'PBPL006104', '9871963829', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/1986', 'Housekeeping', NULL),
(145, 'Aleyamma Babu', 'PBPL006119', '9891568559', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '22/05/1973', 'Center Phlebo', NULL),
(146, 'Mansi Shukla', 'PBPL006118', '8595713150', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '25/10/2002', 'Technical', NULL),
(147, 'jyoti', 'PBPL006120', '9870554746', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '17/09/2003', 'Customer Care', NULL),
(148, 'Salman khan', 'PBPL006121', '9625052126', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '16/06/1999', 'Customer Care', NULL),
(149, 'Abhishek Raikwar', 'PBPL006122', '8882649327', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '16/07/2004', 'Technical', NULL),
(150, 'Naim Ahmed', 'PBPL006124', '7065310620', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '24/07/2006', 'Field', NULL),
(151, 'shama', 'PBPL006125', '9758109554', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/09/2004', 'Technical', NULL),
(152, 'dhirender singh', 'PBPL006127', '9899004178', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '03/11/1977', 'Customer Care', NULL),
(153, 'Aman', 'PBPL006131', '8448872490', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '25/02/2001', 'Technical', NULL),
(154, 'Faizan', 'PBPL096132', '7310874325', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/2006', 'Center Phlebo', NULL),
(155, 'Mohd Arif', 'PBPL006134', '7409996631', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '04/02/2000', 'Home Collection Phlebo', NULL),
(156, 'Pratiksha', 'PBPL006133', '9717180537', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '07/12/1998', 'Center Phlebo', NULL),
(157, 'AMRIT', 'PBPL006126', '8448234277', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/1987', 'Field', NULL),
(158, 'PRINCE KUMAR', 'PBPL006137', '7018048684', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '16/06/2000', 'Technical', NULL),
(159, 'FAJIL JAMALI', 'PBPL006139', '9837185025', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '17/07/1997', 'Home Collection Phlebo', NULL),
(160, 'Asha', 'PBPL006138', '9625982051', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/08/1999', 'House Keeping', NULL),
(161, 'Khubaib Khan', 'PBPL006140', '9540212849', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '08/05/1999', 'Field', NULL),
(162, 'Prashant Tiwari', 'PBPL006143', '9696983009', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '06/07/2002', 'Home Collection Phlebo', NULL),
(163, 'MD IRPHAN ALAM', 'PBPL006145', '7256934838', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '11/08/2002', 'Home Collection Phlebo', NULL),
(164, 'Karan diwakar', 'PBPL006147', '9899326035', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '18/06/2003', 'Admin', NULL),
(165, 'Suhail Ahmad', 'PBPL006141', '9625719649', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '13/08/2002', 'Field', NULL),
(166, 'Dharmendra Kumar', 'PBPL00135', '9990703607', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '05/05/1988', 'Home Collection Phlebo', NULL),
(167, 'Piyush Kant Pandey', 'PBPL006149', '9621991792', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '15/07/2025', 'Admin', NULL),
(168, 'Nurain Alam', 'PBPL006150', '8802011784', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '04/12/1994', 'Home Collection Phlebo', NULL),
(169, 'Imran', 'PBPL006151', '9953157867', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '04/12/1994', 'Home Collection Phlebo', NULL),
(170, 'Farzan Husain', 'PBPL006152', '8882392867', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '23/11/2000', 'Home Collection Phlebo', NULL),
(171, 'Srishti Bhadri', 'PBPL006154', '8287561883', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '10/01/2005', 'Customer Care', NULL),
(172, 'SANKET KUMAR', 'PBPL006060', '7870484426', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/04/2004', 'Technical', NULL),
(173, 'Abhay Pratap Singh', 'PBPL006155', '8077609259', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '02/08/1999', 'Home Collection Phlebo', NULL),
(174, 'Tausif Khan', 'PBPL006156', '9128271925', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '04/05/2003', 'Technical', NULL),
(175, 'Shubh Bhatia', 'PBPL006157', '8178444947', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '03/10/2006', 'Customer Care', NULL),
(176, 'Pankaj Kumar', 'PBPL006158', '9310013690', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '08/03/1982', 'Field', NULL),
(177, 'Nancy Dahiya', 'PBPL006159', '8950213781', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '15/07/2000', 'Admin', NULL),
(508, 'Vansh', 'PBPL006160', '9821226071', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '25/07/2003', 'Field', NULL),
(509, 'Rahul Kumar', 'PBPL006161', '8368402477', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/02/2003', 'Admin', NULL),
(510, 'Naveen Sagar', 'PBPL006162', '9716330697', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '16/04/1998', 'Customer Care', NULL),
(511, 'Sheetal Kumari', 'PBPL006165', '8595877546', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '14/10/2004', 'Technical', NULL),
(512, 'Hanzala Khan', 'PBPL006166', '7302234975', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/04/1999', 'Center Phlebo', NULL),
(513, 'Shivam Rathore', 'PBPL006169', '8882385278', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '12/04/2004', 'Admin', NULL),
(514, 'DISHIKA', 'PBPL006170', '8595614476', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/01/2003', 'Center Phlebo', NULL),
(515, 'Kanchan kumari', 'PBPL006171', '9336950360', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/09/1999', 'Technical', NULL),
(516, 'Avid Khan', 'PBPL006167', '9555231281', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '20/07/1987', 'Field', NULL),
(517, 'Pankaj Kumar', 'PBPL006173', '7042228141', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '14/05/1981', 'Field', NULL),
(518, 'Vikas', 'PBPL006175', '8800183241', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '30/07/1993', 'House Keeping', NULL),
(519, 'Suhail', 'PBPL006172', '9599356068', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '02/04/2001', 'House Keeping', NULL),
(520, 'Dilshad Ali', 'PBPL006176', '8595020105', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '08/06/1993', 'Field', NULL),
(521, 'Divyanshi Kumari', 'PBPL006177', '8929962005', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '27/06/1998', 'Center Phlebo', NULL),
(522, 'SONA', 'PBPL006178', '8076741165', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '14/05/2005', 'Customer Care', NULL),
(523, 'Dhiraj Kumar', 'PBPL006168', '7011372648', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/2002', 'House Keeping', NULL),
(524, 'Shalini Kumari', 'PBPL006179', '9354592130', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '20/06/2005', 'Customer Care', NULL),
(1035, 'Saddam Hussain', 'PBPL006180', '7217716998', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '12/12/1995', 'Home Collection Phlebo', NULL),
(1891, 'Harish sharma', 'PBPL006181', '9991372012', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '16/03/2000', 'Technical', NULL),
(2062, 'Tushar Kumar', 'PBPL006183', '7042384668', '2', 'staff_user', 'Active', '2025-12-26 13:30:12', '09/01/2002', 'House Keeping', NULL),
(2234, 'Rani', 'PBPL006185', '9873439864', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '07/03/2005', 'Technical', NULL),
(2235, 'Shreya', 'PBPL006186', '9958439588', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '13/01/2002', 'Technical', NULL),
(2236, 'Komal kashyap', 'PBPL006188', '9717111565', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '07/08/1996', 'Customer Care', NULL),
(2237, 'Kusum', 'PBPL006187', '8882026294', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '20/09/2003', 'Center Phlebo', NULL),
(2238, 'Prathana', 'PBPL006189', '9310240406', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/2006', 'Center Phlebo', NULL),
(2239, 'Sonia', 'PBPL006190', '7290010403', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '02/02/2002', 'Center Phlebo', NULL),
(2240, 'Shruti keshri', 'PBPL006191', '7557783359', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/08/2001', 'Technical', NULL),
(2241, 'Rohit Bisht', 'PBPL006192', '8126382045', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '10/04/2003', 'Admin', NULL),
(2242, 'Alok kumar singh', 'Pbpl006193', '7253017744', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '30/06/2001', 'Home Collection Phlebo', NULL),
(2243, 'Deepak Tiwari', 'PBPL006194', '7082320507', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '16/03/1998', 'Home Collection Phlebo', NULL),
(2244, 'Gaurav Kumar', 'PBPL006184', '7321992699', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '13/02/2006', 'House Keeping', NULL),
(2245, 'Jai shree gupta', 'PBPL006196', '8756419603', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '04/04/2004', 'Admin', NULL),
(2246, 'ATUL BABU PAL', 'PBPL006197', '9953394818', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '03/11/2005', 'Center Phlebo', NULL),
(2247, 'Deep sahani', 'PBPL006198', '9060366914', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '23/05/2005', 'Center Phlebo', NULL),
(2248, 'Rishita', 'PBPL006199', '7011721571', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '15/07/2005', 'Admin', NULL),
(2249, 'Shivam Dwivedi', 'PBPL006200', '9354352988', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '22/09/2002', 'Home Collection Phlebo', NULL),
(2250, 'Prerna Sharma', 'PBPL006202', '9910773271', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '25/09/1984', 'Customer Care', NULL),
(2251, 'Shyam Kumar', 'PBPL006203', '7482816592', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/2005', 'Admin', NULL),
(2252, 'Divya bisht', 'PBPL006204', '9258180594', '1,6,5', 'staff_user', 'Active', '2025-12-26 13:30:12', '27/05/2006', 'Technical', NULL),
(2253, 'Komal', 'PBPL006201', '8860886621', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '02/10/1990', 'Customer Care', NULL),
(2254, 'Sandeep', 'PBPL006205', '9560932913', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '18/11/1992', 'Field', NULL),
(2255, 'Deepak kumar', 'PBPL006206', '7210236493', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '12/02/2002', 'Home Collection Phlebo', NULL),
(2256, 'Narendra Pal', 'PBPL006207', '8077095025', '5,6', 'staff_user', 'Active', '2025-12-26 13:30:12', '13/01/1993', 'Home Collection Phlebo', NULL),
(2257, 'SONU MAHTO', 'PBPL006208', '8178396134', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '13/07/2000', 'Customer Care', NULL),
(2258, 'Rohan kumar giri', 'PBPL006209', '8292636187', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '04/01/2004', 'Home Collection Phlebo', NULL),
(2259, 'Kiran Pachori', 'PBPL006211', '9625615521', '5', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '04/06/2000', 'Customer Care', NULL),
(2260, 'Sartaj Khan', 'PBPL006195', '9142276775', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '01/01/1995', 'Field', NULL),
(2261, 'Monika Rajput', 'PBPL006213', '8742945845', '5', 'staff_user', 'Active', '2025-12-26 13:30:12', '27/07/1998', 'Admin', NULL),
(2262, 'Shadab Ali', 'PBPL006210', '7088882143', '5,6', 'staff_user', 'Inactive', '2025-12-26 13:30:12', '06/07/2000', 'Home Collection Phlebo', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `department_master`
--
ALTER TABLE `department_master`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `hiccups`
--
ALTER TABLE `hiccups`
  ADD PRIMARY KEY (`hiccup_id`),
  ADD KEY `fk_hiccups_raised_by_dept` (`raised_by_department`),
  ADD KEY `fk_hiccups_raised_against_dept` (`raised_against_department`),
  ADD KEY `fk_hiccups_response_by` (`response_by`),
  ADD KEY `fk_hiccups_escalated_by` (`escalated_by`),
  ADD KEY `idx_hiccups_status_created` (`status`,`created_at`),
  ADD KEY `idx_hiccups_raised_by` (`raised_by`),
  ADD KEY `idx_hiccups_raised_against` (`raised_against`),
  ADD KEY `idx_hiccups_source` (`source_module`);

--
-- Indexes for table `hiccup_audit_log`
--
ALTER TABLE `hiccup_audit_log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `fk_audit_hiccup` (`hiccup_id`),
  ADD KEY `fk_audit_performer` (`performed_by`);

--
-- Indexes for table `infra_tickets`
--
ALTER TABLE `infra_tickets`
  ADD PRIMARY KEY (`ticket_id`),
  ADD KEY `fk_infra_created_by` (`created_by`),
  ADD KEY `fk_infra_department` (`department`),
  ADD KEY `fk_infra_assigned_to` (`assigned_to`);

--
-- Indexes for table `infra_ticket_images`
--
ALTER TABLE `infra_ticket_images`
  ADD PRIMARY KEY (`image_id`),
  ADD KEY `fk_infra_image_ticket` (`ticket_id`);

--
-- Indexes for table `infra_updates`
--
ALTER TABLE `infra_updates`
  ADD PRIMARY KEY (`update_id`),
  ADD KEY `fk_infra_update_ticket` (`ticket_id`),
  ADD KEY `fk_infra_update_created_by` (`created_by`);

--
-- Indexes for table `nc_escalation_forms`
--
ALTER TABLE `nc_escalation_forms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `hiccup_id` (`hiccup_id`),
  ADD KEY `fk_nc_form_assigned_staff` (`assigned_staff_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `contact` (`contact`),
  ADD KEY `ix_users_id` (`id`),
  ADD KEY `ix_users_name` (`name`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `department_master`
--
ALTER TABLE `department_master`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hiccups`
--
ALTER TABLE `hiccups`
  MODIFY `hiccup_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hiccup_audit_log`
--
ALTER TABLE `hiccup_audit_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `infra_tickets`
--
ALTER TABLE `infra_tickets`
  MODIFY `ticket_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `infra_ticket_images`
--
ALTER TABLE `infra_ticket_images`
  MODIFY `image_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `infra_updates`
--
ALTER TABLE `infra_updates`
  MODIFY `update_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nc_escalation_forms`
--
ALTER TABLE `nc_escalation_forms`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2263;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `hiccups`
--
ALTER TABLE `hiccups`
  ADD CONSTRAINT `fk_hiccups_escalated_by` FOREIGN KEY (`escalated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_hiccups_raised_against_dept` FOREIGN KEY (`raised_against_department`) REFERENCES `department_master` (`id`),
  ADD CONSTRAINT `fk_hiccups_raised_by_dept` FOREIGN KEY (`raised_by_department`) REFERENCES `department_master` (`id`),
  ADD CONSTRAINT `fk_hiccups_response_by` FOREIGN KEY (`response_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `hiccup_audit_log`
--
ALTER TABLE `hiccup_audit_log`
  ADD CONSTRAINT `fk_audit_hiccup` FOREIGN KEY (`hiccup_id`) REFERENCES `hiccups` (`hiccup_id`),
  ADD CONSTRAINT `fk_audit_performer` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `infra_tickets`
--
ALTER TABLE `infra_tickets`
  ADD CONSTRAINT `fk_infra_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_infra_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_infra_department` FOREIGN KEY (`department`) REFERENCES `department_master` (`id`);

--
-- Constraints for table `infra_ticket_images`
--
ALTER TABLE `infra_ticket_images`
  ADD CONSTRAINT `fk_infra_image_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `infra_tickets` (`ticket_id`);

--
-- Constraints for table `infra_updates`
--
ALTER TABLE `infra_updates`
  ADD CONSTRAINT `fk_infra_update_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_infra_update_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `infra_tickets` (`ticket_id`);

--
-- Constraints for table `nc_escalation_forms`
--
ALTER TABLE `nc_escalation_forms`
  ADD CONSTRAINT `fk_nc_form_assigned_staff` FOREIGN KEY (`assigned_staff_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_nc_form_hiccup` FOREIGN KEY (`hiccup_id`) REFERENCES `hiccups` (`hiccup_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
