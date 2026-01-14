-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: mysql:3306
-- Generation Time: Jan 14, 2026 at 01:23 PM
-- Server version: 8.4.7
-- PHP Version: 8.3.26

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
  `id` int NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `department_master`
--

INSERT INTO `department_master` (`id`, `name`) VALUES
(1, 'Admin'),
(2, 'Technical'),
(3, 'Customer Care'),
(4, 'Field Operations'),
(5, 'Center Phlebotomy'),
(6, 'Home Collection'),
(7, 'House Keeping'),
(8, 'Administration'),
(9, 'Marketing');

-- --------------------------------------------------------

--
-- Table structure for table `hiccups`
--

CREATE TABLE `hiccups` (
  `hiccup_id` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `raised_by` int NOT NULL,
  `raised_by_department` int DEFAULT NULL,
  `hiccup_type` enum('Person Related','System Related') COLLATE utf8mb4_general_ci NOT NULL,
  `raised_against` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `raised_against_department` int DEFAULT NULL,
  `description` text COLLATE utf8mb4_general_ci NOT NULL,
  `immediate_effect` text COLLATE utf8mb4_general_ci,
  `attachment_path` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `response_by` int DEFAULT NULL,
  `response_text` text COLLATE utf8mb4_general_ci,
  `status` enum('Open','Responded','Under Review','Closed','Escalated to NC') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Open',
  `escalated_by` int DEFAULT NULL,
  `root_cause` text COLLATE utf8mb4_general_ci,
  `corrective_action` text COLLATE utf8mb4_general_ci,
  `closure_notes` text COLLATE utf8mb4_general_ci,
  `closed_at` datetime DEFAULT NULL,
  `is_auto_generated` tinyint(1) NOT NULL DEFAULT '0',
  `source_module` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `confidential_flag` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `followup_status` enum('Pending','Resolved','Unresolved') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Pending',
  `followup_comment` text COLLATE utf8mb4_general_ci,
  `root_cause_category` enum('Training Need','Process Gap','Negligence','System Error','External Factor','Resource Shortage') COLLATE utf8mb4_general_ci DEFAULT NULL,
  `is_response_overdue` tinyint(1) NOT NULL DEFAULT '0',
  `is_closure_overdue` tinyint(1) NOT NULL DEFAULT '0',
  `raised_by_name` varchar(150) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `raised_against_name` varchar(150) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `response_by_name` varchar(150) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `raised_against_department_name` varchar(150) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `response_blocked` tinyint(1) NOT NULL DEFAULT '0',
  `reminder_sent` tinyint(1) NOT NULL DEFAULT '0',
  `overdue_msg_sent` tinyint(1) NOT NULL DEFAULT '0',
  `escalate_msg_sent` tinyint(1) NOT NULL DEFAULT '0',
  `nc_assigned_staff_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hiccups`
--

INSERT INTO `hiccups` (`hiccup_id`, `raised_by`, `raised_by_department`, `hiccup_type`, `raised_against`, `raised_against_department`, `description`, `immediate_effect`, `attachment_path`, `response_by`, `response_text`, `status`, `escalated_by`, `root_cause`, `corrective_action`, `closure_notes`, `closed_at`, `is_auto_generated`, `source_module`, `confidential_flag`, `created_at`, `updated_at`, `followup_status`, `followup_comment`, `root_cause_category`, `is_response_overdue`, `is_closure_overdue`, `raised_by_name`, `raised_against_name`, `response_by_name`, `raised_against_department_name`, `response_blocked`, `reminder_sent`, `overdue_msg_sent`, `escalate_msg_sent`, `nc_assigned_staff_id`) VALUES
('HCP-26-002', 35, NULL, 'Person Related', '40', 9, 'FOR TESTING', NULL, NULL, NULL, NULL, 'Closed', NULL, NULL, NULL, 'Trial', '2026-01-13 19:33:40', 0, NULL, 0, '2026-01-12 19:27:14', '2026-01-13 19:33:40', 'Pending', NULL, NULL, 0, 0, 'Shahana Parveen', 'Gunjan mehta', NULL, 'Marketing', 0, 1, 0, 0, NULL),
('HCP-26-003', 61, NULL, 'Person Related', '94', 2, 'NOT WEARING FORMAL DRESSCODE', NULL, NULL, NULL, NULL, 'Open', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, '2026-01-13 12:25:31', '2026-01-14 15:29:20', 'Pending', NULL, 'Training Need', 1, 0, 'MOHD AARISH', 'Sarika', NULL, 'Technical', 0, 1, 1, 0, NULL),
('HCP-26-004', 7, NULL, 'Person Related', '51', 6, 'BATUL BAGUM URINE SAMPLE EXTRA ', NULL, NULL, NULL, NULL, 'Open', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, '2026-01-13 12:42:26', '2026-01-14 15:29:20', 'Pending', NULL, NULL, 1, 0, 'Ritu Mahalwal', 'Mahendra pal', NULL, 'Home Collection Phlebo', 0, 1, 1, 0, NULL),
('HCP-26-006', 35, NULL, 'Person Related', '6', 3, 'ON SATURDAY REPLIED IN DR POOJA RANA GROUP FOR CONNECTING DR POOJA CALL TO DR NITIKA ON SUNDAY, GIVES COMMITMNET TO DR POOJA BUT CALL NOT CONNECTED ON SUNDAY\n\nON 12.01.2026 GIVE REPLY IN COCCON GROUP FOR SHARING CS REPORT BUT NOT SHARED TILL 13.1.26, 7:35PM', NULL, NULL, 6, 'SO SORRY', 'Responded', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, '2026-01-13 19:43:10', '2026-01-14 12:51:19', 'Pending', NULL, NULL, 0, 0, 'Shahana Parveen', 'Sanjeet Kumar', 'Sanjeet Kumar', 'Customer Care', 0, 0, 0, 0, NULL),
('HCP-26-007', 2262, NULL, 'Person Related', '120', 6, 'Mr. Kalim collects the daily collections late. When you call him, he says that it’s getting late because you are calling.', NULL, NULL, NULL, NULL, 'Open', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, '2026-01-14 09:31:55', '2026-01-14 09:31:55', 'Pending', NULL, NULL, 0, 0, 'Shadab Ali', 'Md Kalim', NULL, 'Home Collection Phlebo', 0, 0, 0, 0, NULL),
('HCP-26-008', 147, NULL, 'Person Related', '2266', 3, 'IN THE MORNING WHEN I ENTERED SAW SO MUCH DUST  AND MY  SYSTEM WAS  USED YESTERDAY NOT SHUT DOWN ,EVEN IT WAS LOG IN BY YOUR ID  WHICH IS NOT THE CORRECT WAY SAME COMPLAINED BY CCE STAFF PRERNA ALSO .', NULL, NULL, NULL, NULL, 'Open', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, '2026-01-14 10:31:37', '2026-01-14 10:31:37', 'Pending', NULL, 'Negligence', 0, 0, 'jyoti', 'Khushiya khan', NULL, 'Customer Care', 0, 0, 0, 0, NULL),
('HCP-26-009', 7, NULL, 'Person Related', '2250', 3, 'patient name namrita srivastav collection not booked but update booked in lead ', NULL, NULL, 2250, 'DEAR MA\'AM,\n\nI REALLY APPOLOGISED FOR THE MISTAKE I WILL KEEP IN MIND IN FUTURE \n\nREGARDS \nPRERNA SHARMA', 'Closed', NULL, NULL, NULL, 'No Actions', '2026-01-14 14:57:07', 0, NULL, 0, '2026-01-14 10:57:24', '2026-01-14 14:57:08', 'Pending', NULL, NULL, 0, 0, 'Ritu Mahalwal', 'Prerna Sharma', 'Prerna Sharma', 'Customer Care', 0, 0, 0, 0, NULL),
('HCP-26-010', 2262, NULL, 'Person Related', '85', 3, '“Salim sir has given half day, and I have no information anywhere—neither in the group, not on PetPooja, not on the roster.”', NULL, NULL, NULL, NULL, 'Open', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, '2026-01-14 11:19:34', '2026-01-14 11:19:34', 'Pending', NULL, NULL, 0, 0, 'Shadab Ali', 'SALEEM JAVED', NULL, 'Customer Care', 0, 0, 0, 0, NULL),
('HCP-26-013', 17, NULL, 'Person Related', '516', 4, 'without information on leave 4 days off duty', NULL, NULL, NULL, NULL, 'Open', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, '2026-01-14 12:52:34', '2026-01-14 12:52:34', 'Pending', NULL, NULL, 0, 0, 'Aman Shukla', 'Avid Khan', NULL, 'Field', 0, 0, 0, 0, NULL),
('HCP-26-014', 2241, NULL, 'Person Related', '2241', 8, 'test', NULL, NULL, 2241, 'sorry', 'Closed', 125, NULL, NULL, 'ok no problem', '2026-01-14 16:17:57', 0, NULL, 0, '2026-01-14 13:28:18', '2026-01-14 16:17:57', 'Pending', NULL, NULL, 0, 0, 'Rohit Bisht', 'Rohit Bisht', 'Rohit Bisht', 'Admin', 0, 0, 0, 0, 2241),
('HCP-26-015', 2241, NULL, 'Person Related', '2241', 8, 'testing', NULL, NULL, NULL, NULL, 'Closed', NULL, NULL, NULL, 'ok', '2026-01-14 16:19:17', 0, NULL, 0, '2026-01-14 16:18:57', '2026-01-14 16:19:17', 'Pending', NULL, NULL, 0, 0, 'Rohit Bisht', 'Rohit Bisht', NULL, 'Admin', 0, 0, 0, 0, NULL),
('HCP-26-016', 95, NULL, 'Person Related', '63', 3, 'WRONG PATIENT NAME MENTIONED (152510041779)', NULL, NULL, NULL, NULL, 'Open', NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, '2026-01-14 17:21:39', '2026-01-14 17:21:39', 'Pending', NULL, NULL, 0, 0, 'ANKITA', 'AMAN CHOTALA', NULL, 'Customer Care', 0, 0, 0, 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `hiccup_audit_log`
--

CREATE TABLE `hiccup_audit_log` (
  `log_id` int NOT NULL,
  `hiccup_id` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `action` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `performed_by` int NOT NULL,
  `timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `remarks` text COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hiccup_audit_log`
--

INSERT INTO `hiccup_audit_log` (`log_id`, `hiccup_id`, `action`, `performed_by`, `timestamp`, `remarks`) VALUES
(2, 'HCP-26-001', 'Responded', 35, '2026-01-12 19:23:48', NULL),
(4, 'HCP-26-002', 'Created', 35, '2026-01-12 19:27:14', NULL),
(5, 'HCP-26-003', 'Created', 61, '2026-01-13 12:25:31', NULL),
(6, 'HCP-26-004', 'Created', 7, '2026-01-13 12:42:27', NULL),
(10, 'HCP-26-006', 'Created', 35, '2026-01-13 19:43:10', NULL),
(11, 'HCP-26-007', 'Created', 2262, '2026-01-14 09:31:55', NULL),
(12, 'HCP-26-008', 'Created', 147, '2026-01-14 10:31:37', NULL),
(13, 'HCP-26-009', 'Created', 7, '2026-01-14 10:57:24', NULL),
(14, 'HCP-26-010', 'Created', 2262, '2026-01-14 11:19:34', NULL),
(15, 'HCP-26-009', 'Responded', 2250, '2026-01-14 11:30:36', NULL),
(23, 'HCP-26-012', 'Updated NC form', 124, '2026-01-14 12:33:08', NULL),
(24, 'HCP-26-012', 'StatusChanged', 124, '2026-01-14 12:33:08', 'Closed'),
(25, 'HCP-26-011', 'StatusChanged', 124, '2026-01-14 12:34:16', 'Escalated to NC'),
(34, 'HCP-26-013', 'Created', 17, '2026-01-14 12:52:35', NULL),
(35, 'HCP-26-014', 'Created', 2241, '2026-01-14 13:28:18', NULL),
(36, 'HCP-26-014', 'Responded', 2241, '2026-01-14 13:28:38', NULL),
(37, 'HCP-26-014', 'StatusChanged', 125, '2026-01-14 13:29:25', 'Escalated to NC'),
(38, 'HCP-26-014', 'StatusChanged', 125, '2026-01-14 13:33:37', 'Escalated to NC'),
(39, 'HCP-26-014', 'StatusChanged', 125, '2026-01-14 13:37:03', 'Escalated to NC'),
(40, 'HCP-26-014', 'StatusChanged', 125, '2026-01-14 13:43:34', 'Closed'),
(41, 'HCP-26-014', 'StatusChanged', 125, '2026-01-14 13:51:30', 'Escalated to NC'),
(42, 'HCP-26-014', 'Updated NC form', 2241, '2026-01-14 13:51:44', NULL),
(43, 'HCP-26-014', 'StatusChanged', 2241, '2026-01-14 13:51:44', 'Closed'),
(44, 'HCP-26-014', 'Updated NC form', 2241, '2026-01-14 13:56:24', NULL),
(45, 'HCP-26-014', 'Updated NC form', 125, '2026-01-14 14:01:23', NULL),
(46, 'HCP-26-014', 'StatusChanged', 125, '2026-01-14 14:01:23', 'Closed'),
(47, 'HCP-26-014', 'Updated NC form', 125, '2026-01-14 14:01:32', NULL),
(48, 'HCP-26-014', 'StatusChanged', 125, '2026-01-14 14:01:32', 'Closed'),
(49, 'HCP-26-009', 'StatusChanged', 125, '2026-01-14 14:57:08', 'Closed'),
(50, 'HCP-26-006', 'Responded', 6, '2026-01-14 15:33:05', NULL),
(51, 'HCP-26-014', 'StatusChanged', 125, '2026-01-14 16:17:57', 'Closed'),
(52, 'HCP-26-015', 'Created', 2241, '2026-01-14 16:18:57', NULL),
(53, 'HCP-26-015', 'StatusChanged', 125, '2026-01-14 16:19:17', 'Closed'),
(54, 'HCP-26-016', 'Created', 95, '2026-01-14 17:21:39', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `infra_tickets`
--

CREATE TABLE `infra_tickets` (
  `ticket_id` int NOT NULL,
  `created_by` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `department` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `subcategory` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `workstation` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `assigned_to` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `commitment_time` datetime DEFAULT NULL,
  `is_delayed_pick` tinyint(1) NOT NULL,
  `is_invalid` tinyint(1) NOT NULL,
  `invalid_reason` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `image_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `reminder_sent` tinyint(1) NOT NULL DEFAULT '0',
  `contact` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `infra_tickets`
--

INSERT INTO `infra_tickets` (`ticket_id`, `created_by`, `department`, `category`, `subcategory`, `description`, `workstation`, `status`, `assigned_to`, `commitment_time`, `is_delayed_pick`, `is_invalid`, `invalid_reason`, `image_path`, `created_at`, `updated_at`, `reminder_sent`, `contact`) VALUES
(1, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'KINDLY GIVE PERMISSION TO CREATE MARKETING EXECUTIVE IN LABMATE', 'Workstation 22', 'Resolved', 'RAHNUMA KHATOON', '2025-12-01 14:00:00', 0, 0, NULL, NULL, '2025-11-28 20:30:21', '2025-12-01 12:14:40', 0, NULL),
(2, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA', 'HOME COLLECTION SUMMARY PP AT FASTING TIME .', 'Workstation 29', 'Resolved', 'SAHIL BISHT', '2025-12-01 16:00:00', 0, 0, NULL, NULL, '2025-11-29 10:28:42', '2025-12-01 12:29:22', 0, NULL),
(3, 'SAHIL BISHT', 'Technical', 'Software', 'Other software', 'DUmmy', 'Workstation 1', 'Resolved', NULL, NULL, 0, 0, NULL, NULL, '2025-11-29 12:49:50', '2025-11-29 12:53:03', 0, NULL),
(4, 'SAHIL BISHT', 'Other', 'Other', 'Other', 'testing', NULL, 'Resolved', NULL, NULL, 0, 0, NULL, NULL, '2025-11-29 12:58:10', '2025-11-29 12:58:32', 0, NULL),
(5, 'Rohit Bisht', 'Technical', 'Hardware', 'Keyboard/Mouse', 'mouse is not working properly', NULL, 'Resolved', 'Ritesh Kumar', '2025-11-30 13:15:00', 1, 0, NULL, NULL, '2025-11-29 15:22:40', '2025-11-30 13:16:22', 0, NULL),
(6, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA', 'NEGATIVE FEED BACK NOT RECEIVED', 'Workstation 29', 'Resolved', 'RAHNUMA KHATOON', '2025-11-29 17:00:00', 0, 0, NULL, NULL, '2025-11-29 16:10:28', '2025-11-29 16:50:19', 0, NULL),
(7, 'RAHNUMA KHATOON', 'Technical', 'Software', 'ARPRA', 'I have to give old negative feedback to Call center on Monday', NULL, 'Resolved', NULL, NULL, 0, 0, NULL, NULL, '2025-11-29 16:57:05', '2025-12-01 13:28:46', 0, NULL),
(8, 'GIRDHAR SINGH BORA', 'Other', 'Other', 'Other', 'ONE LIGHT NOT WORKING AT THE ELISA LAB AREA', 'Workstation 62', 'Resolved', 'Ritesh Kumar', '2025-11-30 13:30:00', 0, 0, NULL, NULL, '2025-11-30 12:30:41', '2025-11-30 13:07:43', 0, NULL),
(9, 'Sanjeet Kumar', 'Technical', 'Software', 'ARPRA', 'Center pick call is ringing without pickup in the system.', 'Workstation 30', 'Resolved', NULL, NULL, 0, 0, NULL, 'uploads/infra/20251130150050_WhatsApp_Image_2025-11-30_at_2.36.42_PM.jpeg', '2025-11-30 15:00:50', '2025-12-01 13:31:10', 0, NULL),
(10, 'Dr Vipul Bhasin', 'Other', 'Other', 'Other', 'In 2nd floor hall outside washroom, wire burning smell is coming!', NULL, 'Resolved', 'Ritesh Kumar', '2025-12-01 20:00:00', 0, 0, NULL, NULL, '2025-11-30 19:59:05', '2025-12-01 11:55:33', 0, NULL),
(11, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA', 'IN SUMMARY SHEET PP SHOWING ON FASTING TIME .', 'Workstation 29', 'Resolved', 'SAHIL BISHT', '2025-12-01 12:45:00', 0, 0, NULL, NULL, '2025-12-01 09:06:54', '2025-12-01 12:28:59', 0, NULL),
(12, 'Ritesh Kumar', 'Other', 'Other', 'Other', 'dilshad 7 november 2025 sunday ke din histo department me welding ka kam krenge.', 'Workstation 58', 'Resolved', 'Ritesh Kumar', '2025-12-07 18:00:00', 1, 0, NULL, NULL, '2025-12-01 11:59:07', '2025-12-18 19:14:42', 0, '9695983021'),
(13, 'Shubh Bhatia', 'Customer Care', 'Software', 'Other software', 'PDF AND EXCEL ARE NOT WORKING IN MY SYSTEM', 'Workstation 20', 'Resolved', NULL, NULL, 0, 0, NULL, NULL, '2025-12-01 12:06:19', '2025-12-01 13:42:18', 0, NULL),
(14, 'Shalini Kumari', 'Customer Care', 'Software', 'Labmate', 'AUTO REPORT NOT GOING', 'Workstation 25', 'Resolved', 'RAHNUMA KHATOON', '2025-12-01 15:00:00', 1, 0, NULL, NULL, '2025-12-01 13:06:12', '2025-12-02 12:10:38', 0, NULL),
(15, 'Shalini Kumari', 'Customer Care', 'Hardware', 'Printer/Scanner', 'PRINTER IS NOT ATTACHED', 'Workstation 25', 'Resolved', 'Ritesh Kumar', '2025-12-02 12:45:00', 0, 0, NULL, NULL, '2025-12-01 13:06:47', '2025-12-02 12:31:01', 0, NULL),
(16, 'ANKITA', 'Customer Care', 'Hardware', 'Network port/LAN', 'LABMATE NOT WORKING', 'Workstation 47', 'Resolved', 'RAHNUMA KHATOON', '2025-12-01 14:30:00', 0, 0, NULL, NULL, '2025-12-01 13:08:23', '2025-12-01 13:39:58', 0, NULL),
(17, 'Akash yadav', 'Customer Care', 'Hardware', 'Printer/Scanner', 'PRINTER IS NOT CONNECTED FOR MY SYSTEM.', 'Workstation 26', 'Resolved', 'Ritesh Kumar', '2025-12-02 12:45:00', 0, 0, NULL, NULL, '2025-12-01 13:08:49', '2025-12-02 12:30:51', 0, NULL),
(18, 'Jyoti Marwah', 'Technical', 'Hardware', 'Other Hardware', 'WASHROOM DOOR  HANDLE BROKEN', 'Workstation 52', 'Resolved', 'Ritesh Kumar', '2025-12-01 16:00:00', 0, 0, NULL, NULL, '2025-12-01 15:34:15', '2025-12-01 15:46:07', 0, NULL),
(19, 'VIMAL RANJAN PANDEY', 'Technical', 'Software', 'Labmate', 'PLEASE ADD HIV RNA IN WORKSTATION DAISORIN', 'Workstation 61', 'Resolved', 'RAHNUMA KHATOON', '2025-12-02 13:00:00', 0, 0, NULL, NULL, '2025-12-01 15:39:35', '2025-12-02 12:16:21', 0, NULL),
(20, 'Shahana Parveen', 'Marketing', 'Other', 'Other', 'REQUIRED NEW PAYMENT QR CODE SCANNER FOR DERMA AIIMS', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-02 15:00:00', 0, 0, NULL, NULL, '2025-12-01 16:04:11', '2025-12-02 12:24:40', 0, NULL),
(21, 'Shubh Bhatia', 'Customer Care', 'Software', 'Labmate', 'PLEASE GIVE PERMISSION FOR ENTER REPORT IN LABMATE FOR ALLERGY PROFILE REPORT', 'Workstation 20', 'Resolved', 'RAHNUMA KHATOON', '2025-12-02 12:15:00', 0, 0, NULL, NULL, '2025-12-01 18:09:19', '2025-12-02 12:09:30', 0, NULL),
(22, 'Rohit Bisht', 'Technical', 'Software', 'Other software', 'testing software', NULL, 'Resolved', 'Rohit Bisht', '2025-12-02 12:15:00', 0, 0, NULL, NULL, '2025-12-02 12:04:36', '2025-12-02 12:05:35', 0, NULL),
(23, 'RAHNUMA KHATOON', 'Technical', 'Other', 'Other', 'Need jio router credential', NULL, 'Resolved', 'Rohit Bisht', '2025-12-03 12:45:00', 0, 0, NULL, NULL, '2025-12-02 13:06:22', '2025-12-03 07:05:32', 0, NULL),
(24, 'RAHNUMA KHATOON', 'Technical', 'Other', 'Other', 'Labmate update 7002', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-05 15:00:00', 0, 0, NULL, NULL, '2025-12-02 13:09:57', '2025-12-05 10:08:21', 0, NULL),
(25, 'Sanjeet Kumar', 'Customer Care', 'Software', 'ARPRA Neo', 'NOT CLAIM CALL  SHOWING  LONG CALL', NULL, 'Resolved', 'SAHIL BISHT', '2025-12-02 14:15:00', 0, 0, NULL, 'uploads/infra/20251202131531_WhatsApp_Image_2025-12-02_at_1.02.30_PM.jpeg', '2025-12-02 13:15:31', '2025-12-02 14:11:59', 0, NULL),
(26, 'ANKITA', 'Customer Care', 'Other', 'Other', 'all anc profile opened in  dr chitra das panel', 'Workstation 47', 'Resolved', 'Ritesh Kumar', '2025-12-05 13:15:00', 0, 0, NULL, NULL, '2025-12-02 13:19:00', '2025-12-05 07:54:30', 0, NULL),
(27, 'Gulrez Sultan', 'Customer Care', 'Office Infra', 'Lights/Fans issue', 'ग्राउंड फ्लोर की 4 लाइटें ठीक से काम नहीं कर रही हैं !', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2025-12-04 12:00:00', 0, 0, NULL, NULL, '2025-12-02 13:44:30', '2025-12-04 06:27:47', 0, NULL),
(28, 'Dr Vipul Bhasin', 'Other', 'Software', 'Other software', 'Delete/Uninstall - Cosec App from old server', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-03 15:30:00', 0, 0, NULL, NULL, '2025-12-02 14:57:55', '2025-12-03 07:15:37', 0, NULL),
(29, 'Dr Vipul Bhasin', 'Other', 'Hardware', 'Other Hardware', 'RAM needs to increase on the Old Server', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-05 15:00:00', 0, 0, NULL, NULL, '2025-12-02 14:58:24', '2025-12-05 10:08:09', 0, NULL),
(30, 'Ritesh Kumar', 'Admin', 'Office Infra', 'Other', 'RO filters need to be change', NULL, 'Resolved', 'Ritesh Kumar', '2025-12-02 19:00:00', 0, 0, NULL, NULL, '2025-12-02 18:50:03', '2025-12-02 18:50:27', 0, NULL),
(31, 'Rohit Bisht', 'Technical', 'Software', 'Other software', 'testing-software', NULL, 'Resolved', 'Rohit Bisht', '2025-12-02 20:00:00', 0, 0, NULL, NULL, '2025-12-02 14:19:54', '2025-12-02 14:20:22', 0, NULL),
(32, 'Md Shaquib Alam', 'Technical', 'Hardware', 'CPU', 'KINDLY CHANGE CPU AND INSTALL INTERFACE & QC DART OF ATEELICA INSTRUMENT.', 'Workstation 42', 'Resolved', 'RAHNUMA KHATOON', '2025-12-03 15:00:00', 0, 0, NULL, NULL, '2025-12-03 05:30:15', '2025-12-03 08:09:01', 0, NULL),
(33, 'Gulrez Sultan', 'Other', 'Other', 'Other', 'YELLOW LIGHT IS NOT WORKING IN SAMPLE COLLECTION ROOM', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2025-12-07 16:00:00', 1, 0, NULL, 'uploads/infra/20251203060322_SAMPLE_COLLECTION.jpeg', '2025-12-03 06:03:22', '2025-12-17 17:23:55', 0, '9818247844'),
(36, 'IT Team', 'Main Lab Room', 'software', 'sensor', 'No new readings since 05 Jun 2025 12:10 PM', 'Main Lab Room', 'New', NULL, NULL, 0, 0, NULL, NULL, '2025-12-03 12:12:20', '2025-12-10 13:52:09', 1, NULL),
(37, 'IT Team', 'RTPCR Out Area Freezer', 'software', 'sensor', 'No new readings since 29 Oct 2025 06:57 PM', 'RTPCR Out Area Freezer', 'New', NULL, NULL, 0, 0, NULL, NULL, '2025-12-03 12:12:20', '2025-12-10 13:52:09', 1, NULL),
(38, 'Vivek kumar Tiwari', 'Admin', 'Hardware', 'CPU', 'CPU IS NOT WORKING.', 'Workstation 8', 'Resolved', 'Ritesh Kumar', '2025-12-03 13:00:00', 0, 0, NULL, NULL, '2025-12-03 07:10:32', '2025-12-03 07:29:45', 0, NULL),
(39, 'Jaspal singh rawat', 'Customer Care', 'Hardware', 'Telephone', 'TELEPHONE NOT WORKING PROPERLY', 'Workstation 23', 'Resolved', 'Ritesh Kumar', '2025-12-03 14:30:00', 0, 0, NULL, NULL, '2025-12-03 08:51:51', '2025-12-03 08:59:56', 0, NULL),
(40, 'Jyoti Marwah', 'Technical', 'Software', 'Labmate', 'GLUCOSE CHALLENGE TEST (GCT ) KINDLY MAPPED IN COBASPURE AND ATELLICA INSTRUMENT.', 'Workstation 24', 'Resolved', 'RAHNUMA KHATOON', '2025-12-09 14:00:00', 0, 0, NULL, NULL, '2025-12-03 10:38:18', '2025-12-09 07:42:53', 0, NULL),
(41, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'need hardcopy or soft copy of report attatched (7 year old )', 'Workstation 29', 'Resolved', 'Dr Vipul Bhasin', '2025-12-08 21:00:00', 0, 0, NULL, 'uploads/infra/20251203105034_vineeta_.jpeg', '2025-12-03 10:50:34', '2025-12-08 15:20:02', 0, NULL),
(42, 'IT Team', 'Extraction Room Freezer', 'software', 'sensor', 'Extraction Room Freezer sensor reading 1.2°C outside expected 2.0°C - 8.0°C', 'Extraction Room Freezer', 'New', NULL, NULL, 0, 0, NULL, NULL, '2025-12-03 17:26:26', '2025-12-10 13:52:09', 1, NULL),
(43, 'Shubh Bhatia', 'Customer Care', 'Software', 'Other software', 'NOT ABEL TO PRINT', 'Workstation 20', 'Resolved', 'Ritesh Kumar', '2025-12-03 19:30:00', 0, 0, NULL, NULL, '2025-12-03 12:41:49', '2025-12-03 13:56:55', 0, NULL),
(44, 'ANKITA', 'Customer Care', 'Other', 'Other', 'TEST OPENED (G04 , S05 , T56 IN HOPE PANEL. CHARGES 16000 (50% DIS )', 'Workstation 2', 'Resolved', 'Ritesh Kumar', '2025-12-05 15:45:00', 0, 0, NULL, NULL, '2025-12-03 13:00:06', '2025-12-05 10:24:40', 0, NULL),
(45, 'Dr Vipul Bhasin', 'Other', 'Hardware', 'Keyboard/Mouse', 'Need a new mouse on my station', NULL, 'Resolved', 'Ritesh Kumar', '2025-12-04 12:00:00', 0, 0, NULL, NULL, '2025-12-03 14:47:00', '2025-12-04 06:06:28', 0, NULL),
(46, 'Gulrez Sultan', 'Other', 'Office Infra', 'Electrical issue', 'ISSUES - \r\n4 LIGHTS IN LOBBY\r\n1 ROUND LIGHT IN SAMPLE COLLECTION \r\n1 LIGHT IN TEMPLE AREA', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2025-12-07 18:00:00', 1, 0, NULL, NULL, '2025-12-04 05:37:28', '2025-12-17 17:23:43', 0, '9818247844'),
(47, 'Rohit Kumar Pandey', 'Admin', 'Office Infra', 'Other', 'Wall paint looking ugly, polish needed', 'Workstation 10', 'Resolved', 'Ritesh Kumar', '2025-12-04 11:45:00', 0, 0, NULL, 'uploads/infra/20251204061056_20251204_113943.jpg', '2025-12-04 06:10:56', '2025-12-04 06:14:50', 0, NULL),
(48, 'Sumit Sirishwal', 'Customer Care', 'Software', 'ARPRA', 'WE DON\'T HAVE ANY PENDING PICKUP BUT SYSTEM IS GENERATING PICKUP CALLS AND GIVING ALERT MESSAGES ON WHATSAPP', 'Workstation 23', 'Resolved', 'RAHNUMA KHATOON', '2025-12-05 13:30:00', 0, 0, NULL, 'uploads/infra/20251204100734_Screenshot_2025-12-04_153716.png', '2025-12-04 10:07:34', '2025-12-05 07:50:58', 0, NULL),
(49, 'Jyoti Marwah', 'Technical', 'Hardware', 'Telephone', 'TELEPHONE NOT WORKING PROPERLY CRACKING SOUND IN BIOCHECMISTRY DEPARMENT', 'Workstation 22', 'Resolved', 'Ritesh Kumar', '2025-12-05 12:15:00', 0, 0, NULL, NULL, '2025-12-04 12:24:59', '2025-12-05 06:43:15', 0, NULL),
(50, 'Md Shaquib Alam', 'Technical', 'Software', 'Labmate', 'KINDLY MAPPED LUCOCYTE ESTRASE IN URINE ROUTINE SPECIALLY IN MADAN FAMILY PANEL .REFRENCE PATIENT ID (102553138).', 'Workstation 28', 'Resolved', 'RAHNUMA KHATOON', '2025-12-09 13:30:00', 0, 0, NULL, NULL, '2025-12-04 12:29:55', '2025-12-09 08:14:23', 0, NULL),
(51, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'KINDLY UPDATE DENGUE  NS1 ANTIGEN  CAHRGES IN SVASTHAM PANEL COMPAY \r\nMRP-1000, 50% DISC ALLOWED', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-09 14:00:00', 0, 0, NULL, NULL, '2025-12-04 12:44:30', '2025-12-09 08:24:55', 0, NULL),
(52, 'Shalini Kumari', 'Customer Care', 'Software', 'Labmate', 'PT. ID - 102552843 PT. NAME - SAARA TALWAR \r\nISS PATIENT K PAS HAR HALF AN HOUR MAI REPORT SEND HO RHI HN AND AGAIN & AGAIN REPORT FAILURE M BHI SHOW HO RHI HN', 'Workstation 27', 'Rejected', NULL, NULL, 0, 1, 'sending by staff', NULL, '2025-12-05 04:39:30', '2025-12-05 07:53:53', 0, NULL),
(53, 'Prerna', 'Technical', 'Hardware', 'Other Hardware', 'AUTOCLAVE NOT WORKING PROPERLY', 'Workstation 59', 'Resolved', 'Ritesh Kumar', '2025-12-05 15:00:00', 1, 0, NULL, NULL, '2025-12-05 07:02:36', '2025-12-30 16:08:20', 0, '8826879686'),
(54, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA', 'there is no pickup pending in system but continuously we receive voice intimation for pending pickup .', 'Workstation 30', 'Resolved', 'RAHNUMA KHATOON', '2025-12-05 13:30:00', 0, 0, NULL, NULL, '2025-12-05 07:10:34', '2025-12-05 07:46:03', 0, NULL),
(55, 'Sheetal Kumari', 'Other', 'Software', 'Labmate', 'Please allow me for TNP authentication (for clinical pathology reports)', 'Workstation 28', 'Resolved', 'RAHNUMA KHATOON', '2025-12-05 15:00:00', 1, 0, NULL, NULL, '2025-12-05 07:28:26', '2025-12-06 07:42:42', 0, NULL),
(56, 'Tausif Khan', 'Other', 'Software', 'Labmate', 'Please allow me for TNP authentication (for clinical pathology reports)', 'Workstation 28', 'Resolved', 'RAHNUMA KHATOON', '2025-12-05 15:00:00', 1, 0, NULL, NULL, '2025-12-05 07:30:22', '2025-12-06 07:42:54', 0, NULL),
(57, 'Gulrez Sultan', 'Customer Care', 'Software', 'Other software', 'NOT ABLE TO UPLOAD EXCEL FILE FROM WORKSTATION 1 & 2', NULL, 'Resolved', 'SAHIL BISHT', '2025-12-06 18:00:00', 0, 0, NULL, NULL, '2025-12-05 09:11:30', '2025-12-06 12:26:52', 0, NULL),
(58, 'ANKITA', 'Customer Care', 'Software', 'Other software', 'These are the packages we want to do for surgical profiles. Please share revised pricing for the same.\r\nMAJOR PRE OP : RS 1000\r\nMINOR PRE OP : RS 850\r\nSpecial instruction [ Viral marker card For both and Discount show 50%', 'Workstation 47', 'Resolved', 'Dr Vipul Bhasin', '2025-12-08 21:00:00', 0, 0, NULL, 'uploads/infra/20251205102136_WhatsApp_Image_2025-12-05_at_3.11.26_PM_(1).jpeg', '2025-12-05 10:21:36', '2025-12-08 15:26:18', 0, NULL),
(59, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'nr sample id -102552818,102553079report send by click on whatsup   report not delivered but not  showing in failure report', 'Workstation 30', 'Resolved', 'RAHNUMA KHATOON', '2025-12-09 14:00:00', 0, 0, NULL, NULL, '2025-12-05 10:28:30', '2025-12-09 08:28:54', 0, NULL),
(60, 'Ravi Kumar Pandey', 'Technical', 'Software', 'Labmate', 'PT MACHINE INTERFACE IS NOT WORKING', 'Workstation 29', 'Resolved', 'SAHIL BISHT', '2025-12-06 18:00:00', 0, 0, NULL, NULL, '2025-12-05 11:42:39', '2025-12-06 12:21:13', 0, NULL),
(61, 'Priyanka Raikwar', 'Other', 'Software', 'Labmate', 'LABMATE NOT OPEN IN 2 DIFFERENT SYSTEMS (33,34)', 'Workstation 33', 'Resolved', 'Ritesh Kumar', '2025-12-06 10:45:00', 0, 0, NULL, NULL, '2025-12-06 03:54:37', '2025-12-06 05:10:51', 0, NULL),
(62, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'not able to login labmate 23,28,35 ,33,34', NULL, 'Resolved', 'Ritesh Kumar', '2025-12-06 10:45:00', 0, 0, NULL, NULL, '2025-12-06 04:23:26', '2025-12-06 05:10:37', 0, NULL),
(63, 'Sheetal Kumari', 'Other', 'Software', 'Labmate', 'ALLOW ME FOR TNP (FOR CLINICAL PATHOLOGY REPORTS )', 'Workstation 28', 'Resolved', 'RAHNUMA KHATOON', '2025-12-06 13:15:00', 0, 0, NULL, NULL, '2025-12-06 07:17:01', '2025-12-06 07:43:09', 0, NULL),
(64, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA Neo', 'IN FAILURE REPORT ID NOT SHOWING , NO SHOWING (DHANBIR )', 'Workstation 30', 'Rejected', NULL, NULL, 0, 1, 'Please read Message Content - It is a Home Collection Booking Message from ARPRA', 'uploads/infra/20251206075620_FAILURE.PNG', '2025-12-06 07:56:20', '2025-12-08 15:25:15', 0, NULL),
(65, 'GIRDHAR SINGH BORA', 'Technical', 'Software', 'Labmate', 'LABMATE NOT WORKING', 'Workstation 57', 'Resolved', 'Ritesh Kumar', '2025-12-06 17:00:00', 0, 0, NULL, NULL, '2025-12-06 09:30:16', '2025-12-06 11:29:42', 0, NULL),
(66, 'Md Shaquib Alam', 'Technical', 'Software', 'Labmate', 'KINDLY UPDATE SAMPLE TYPE IN MTHFR AND FACTOR V . KINDLY UPDATE SAMPLE TYPE EDTA .', 'Workstation 22', 'Resolved', 'RAHNUMA KHATOON', '2025-12-08 15:00:00', 0, 0, NULL, NULL, '2025-12-06 12:33:38', '2025-12-08 09:19:40', 0, NULL),
(67, 'Akash yadav', 'Customer Care', 'Software', 'ARPRA Neo', 'FAILURE REPORT NOT SHOWING LABMATE ID.', 'Workstation 26', 'Rejected', NULL, NULL, 0, 1, 'Please read Message Content - It is a Home Collection Booking Message from ARPRA', 'uploads/infra/20251206125327_Capture_30.PNG', '2025-12-06 12:53:27', '2025-12-08 15:25:03', 0, NULL),
(68, 'Anuj kumar choudhary', 'Technical', 'Hardware', 'Printer/Scanner', 'PRINTER IS NOT WORKING PAPERS GOT STUCK', 'Workstation 46', 'Resolved', 'SALEEM JAVED', '2025-12-13 13:15:00', 1, 0, NULL, NULL, '2025-12-07 07:24:05', '2025-12-13 13:19:45', 1, '9625882897\n'),
(69, 'IT Team', 'Extraction Room', 'software', 'sensor', 'Extraction Room sensor reading 0.0°C outside expected 20.0°C - 35.0°C', 'Extraction Room', 'New', NULL, NULL, 0, 0, NULL, NULL, '2025-12-08 12:18:04', '2025-12-10 13:52:09', 1, NULL),
(70, 'Md Shaquib Alam', 'Technical', 'Software', 'Labmate', 'KINDLY UPDATE SAMPLE TYPE IN CK-MB TEST SERUM TO EDTA', 'Workstation 20', 'Resolved', 'RAHNUMA KHATOON', '2025-12-08 15:00:00', 0, 0, NULL, NULL, '2025-12-08 07:15:55', '2025-12-08 09:19:13', 0, NULL),
(71, 'AMAN CHOTALA', 'Technical', 'Hardware', 'Other Hardware', 'SIR / MAAM PLEASE GET THE AC STOP IN THE RECEPTION AREA PLEASE', 'Workstation 3', 'Resolved', 'SAHIL BISHT', '2025-12-11 20:00:00', 0, 0, NULL, NULL, '2025-12-09 02:45:15', '2025-12-11 19:58:12', 1, '9773552558'),
(72, 'MOHD AARISH', 'Other', 'Hardware', 'CPU', 'SYSTEM NOT WORKING AT SCI INTERNATIONAL HOSPITAL', NULL, 'Resolved', 'Rohit Bisht', '2025-12-09 12:00:00', 0, 0, NULL, NULL, '2025-12-09 03:46:26', '2025-12-09 06:26:27', 0, NULL),
(73, 'Sheetal Kumari', 'Other', 'Software', 'Labmate', 'ALLOW MY ID FOR TNP (CLINICAL REPORT)', 'Workstation 28', 'Resolved', 'RAHNUMA KHATOON', '2025-12-09 14:15:00', 0, 0, NULL, NULL, '2025-12-09 05:00:12', '2025-12-09 08:27:32', 0, NULL),
(74, 'Gulrez Sultan', 'Other', 'Office Infra', 'Lights/Fans issue', '1. GROUND FLOOR LIGHTS ARE NOT WORKING.\r\n2. SAMPLE COLLECTIONN ROOM\'S INNER YELLOW LIGHT NOT WORKING.\r\n3. TEMPLE LIGHT IS NOT WORKING.\r\nALL ABOVE FROM PAST 7 DAYS \r\n4. SAMPLE LIFT ALSO NOT WORKING.', 'Workstation 1', 'Resolved', 'SALEEM JAVED', '2025-12-13 23:45:00', 0, 0, NULL, NULL, '2025-12-09 05:26:03', '2025-12-13 20:55:48', 1, NULL),
(75, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA Neo', 'MESSAGE NOT SHOWING IN FAILURE REPORT', 'Workstation 29', 'Resolved', 'RAHNUMA KHATOON', '2025-12-09 12:45:00', 0, 0, NULL, 'uploads/infra/20251209054742_MESSAGE.PNG', '2025-12-09 05:47:42', '2025-12-09 07:10:25', 0, NULL),
(76, 'Dr Vipul Bhasin', 'Technical', 'Hardware', 'Monitor issue', 'Trial!', NULL, 'Resolved', 'Dr Vipul Bhasin', '2025-12-09 13:45:00', 0, 0, NULL, NULL, '2025-12-09 08:06:50', '2025-12-09 08:08:13', 0, NULL),
(77, 'IT Team', 'Master Mix Room Freeze', 'software', 'sensor', 'No new readings since 09 dec 2025 09:39 AM', 'Master Mix Room Freeze', 'New', NULL, NULL, 0, 0, NULL, NULL, '2025-12-09 13:32:29', '2025-12-10 13:52:09', 1, NULL),
(78, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'CREATE LABMATE ID FOR REGISTRATION \r\n1) RISHITA \r\nPH NO 7011721571\r\n2) JAISHREE GUPTA \r\nPH NO 8756419603', 'Workstation 47', 'Resolved', 'RAHNUMA KHATOON', '2025-12-10 13:00:00', 0, 0, NULL, NULL, '2025-12-09 12:33:46', '2025-12-10 06:39:46', 0, NULL),
(79, 'Jyoti Marwah', 'Technical', 'Software', 'Labmate', 'KINDLY MAKE LABMATE ID FOR STAFF SHRUTI KESHRI', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-10 12:30:00', 0, 0, NULL, NULL, '2025-12-10 06:37:48', '2025-12-10 06:43:19', 0, NULL),
(80, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA Neo', 'tehnician name not update so message failure .', 'Workstation 29', 'Resolved', 'SAHIL BISHT', '2025-12-18 12:30:00', 0, 0, NULL, 'uploads/infra/20251210090726_failure_message.PNG', '2025-12-10 09:07:26', '2025-12-18 12:23:44', 1, '9871366002'),
(81, 'Rohit Bisht', 'Other', 'Other', 'Other', 'testinggg', NULL, 'Rejected', NULL, NULL, 0, 1, 'testing', NULL, '2025-12-10 14:15:58', '2025-12-11 14:45:20', 1, '8126382045'),
(82, 'Rohit Bisht', 'Other', 'Other', 'Other', 'testinggg', NULL, 'Rejected', NULL, NULL, 0, 1, 'testing', NULL, '2025-12-10 14:16:17', '2025-12-11 06:16:19', 0, '8126382045'),
(83, 'Rohit Bisht', 'Other', 'Other', 'Other', 'testinggg', NULL, 'Rejected', 'Rohit Bisht', '2025-12-10 19:00:00', 1, 1, 'testing', NULL, '2025-12-10 14:17:28', '2025-12-11 06:05:19', 0, '8126382045'),
(84, 'Rohit Bisht', 'Other', 'Other', 'Other', 'testing', NULL, 'Resolved', 'Rohit Bisht', '2025-12-10 20:00:00', 0, 0, NULL, NULL, '2025-12-10 14:23:21', '2025-12-10 14:23:44', 0, '8126382045'),
(85, 'Md Shaquib Alam', 'Technical', 'Hardware', 'CPU', 'CPU NOT WORKING DUE TO THIS HPLC REPORTS ARE HOLD.', 'Workstation 50', 'Resolved', 'SAHIL BISHT', '2025-12-11 12:45:00', 0, 0, NULL, NULL, '2025-12-11 06:47:57', '2025-12-11 12:44:47', 0, '8448558464'),
(86, 'Rohit Bisht', 'Other', 'Other', 'Other', 'testing software', NULL, 'Rejected', NULL, NULL, 0, 1, 'testing', NULL, '2025-12-11 07:08:46', '2025-12-11 14:45:12', 0, '8126382045'),
(87, 'Rohit Bisht', 'Other', 'Other', 'Other', 'testing', NULL, 'Rejected', NULL, NULL, 0, 1, 'testing', NULL, '2025-12-11 12:43:34', '2025-12-11 14:45:05', 0, '8126382045'),
(88, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'PIVIKA 2 TEST OPENED RG STONE FARIDABAD 6500 MRP (50% DIS )', 'Workstation 47', 'Resolved', 'ANKITA', '2025-12-20 13:00:00', 0, 0, NULL, NULL, '2025-12-11 16:01:39', '2025-12-20 12:53:45', 1, '8700004157'),
(89, 'Sushil Kumar', 'Technical', 'Hardware', 'Printer/Scanner', 'PRINTER NOT WORKING PROPERLY', NULL, 'Resolved', 'SALEEM JAVED', '2025-12-14 15:45:00', 0, 0, NULL, NULL, '2025-12-12 11:05:23', '2025-12-13 16:54:21', 1, '9717852423'),
(90, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'We booked ena , lab id -102553842 , not showing in pending list report not ready', 'Workstation 30', 'Resolved', 'RAHNUMA KHATOON', '2025-12-12 12:00:00', 0, 0, NULL, 'uploads/infra/20251212112820_DEEPAK.jpeg', '2025-12-12 11:28:21', '2025-12-12 11:57:38', 0, '9871366002'),
(91, 'Harshit', 'Technical', 'Software', 'Labmate', 'labmate not open', 'Workstation 45', 'Resolved', 'SAHIL BISHT', '2025-12-12 12:00:00', 0, 0, NULL, NULL, '2025-12-12 11:29:32', '2025-12-12 11:57:03', 0, '9310305734'),
(92, 'Manwar Singh negi', 'Technical', 'Software', 'Labmate', 'LABMATE NOT WORKING', 'Workstation 44', 'Resolved', 'SAHIL BISHT', '2025-12-12 13:30:00', 1, 0, NULL, NULL, '2025-12-12 12:08:58', '2025-12-12 13:39:31', 0, '9540071850'),
(93, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'NEED  REGISTRATION AUTHORITY IN SHALINI KUMARI ID', 'Workstation 30', 'Resolved', 'RAHNUMA KHATOON', '2025-12-13 13:00:00', 1, 0, NULL, NULL, '2025-12-12 13:47:54', '2025-12-16 12:20:06', 0, '9871366002'),
(94, 'Gulrez Sultan', 'Customer Care', 'Software', 'Labmate', 'KINDLY PROVIDE THE MODIFICATION ACCESS.', 'Workstation 1', 'Resolved', 'RAHNUMA KHATOON', '2025-12-13 15:15:00', 1, 0, NULL, NULL, '2025-12-12 14:57:54', '2025-12-16 14:46:59', 0, '9818247844'),
(95, 'SAHIL BISHT', 'Technical', 'Other', 'Other', 'test', NULL, 'Resolved', 'SAHIL BISHT', '2025-12-12 19:45:00', 0, 0, NULL, NULL, '2025-12-12 18:19:14', '2025-12-12 19:36:34', 0, '8057054076'),
(96, 'SAHIL BISHT', 'Other', 'Other', 'Other', 'sdfwe', 'Workstation 2', 'Resolved', 'SAHIL BISHT', '2025-12-12 19:45:00', 0, 0, NULL, NULL, '2025-12-12 18:36:24', '2025-12-12 19:36:25', 0, '8057054076'),
(97, 'SAHIL BISHT', 'Other', 'Other', 'Other', 'dummy', 'Workstation 2', 'Resolved', 'SAHIL BISHT', '2025-12-12 19:45:00', 0, 0, NULL, NULL, '2025-12-12 19:11:19', '2025-12-12 19:36:11', 0, '8057054076'),
(98, 'Shalini rawat', 'Technical', 'Hardware', 'Keyboard/Mouse', 'KEYBOARD IS NOT WORKING PROPERLY FACING GLITCH IN TYPING KIDNLY PROVIDE NEW KEYBOARD', 'Workstation 46', 'Resolved', 'Rohit Bisht', '2025-12-13 19:00:00', 0, 0, NULL, NULL, '2025-12-13 18:44:28', '2025-12-13 18:53:43', 0, '9650692437'),
(99, 'Md Shaquib Alam', 'Technical', 'Other', 'Other', 'Lab room temperature is high on 1:00 AM, Need to start AC for one hours. Atellica Instrument also shows temperature warning.', 'Workstation 22', 'Resolved', 'Rohit Bisht', '2025-12-15 20:45:00', 0, 0, NULL, NULL, '2025-12-14 01:42:25', '2025-12-15 19:20:48', 0, '8448558464'),
(100, 'Ritu Mahalwal', 'Customer Care', 'Office Infra', 'Lights/Fans issue', 'LIGHT  ISSUE', 'Workstation 29', 'Resolved', 'SALEEM JAVED', '2025-12-18 16:30:00', 0, 0, NULL, NULL, '2025-12-15 15:10:05', '2025-12-17 13:42:10', 1, '9871366002'),
(101, 'Shalini Kumari', 'Customer Care', 'Software', 'Labmate', 'PLEASE PROVIDE ME THE ACCESS OF REGISTRATION', 'Workstation 1', 'Resolved', 'RAHNUMA KHATOON', '2025-12-16 12:45:00', 0, 0, NULL, NULL, '2025-12-16 10:37:53', '2025-12-16 12:38:17', 0, '9354592130'),
(102, 'MD ARIF SAIFI', 'Admin', 'Software', 'Labmate', 'PLEASE GIVE PERMISSION OF MAKE BILL IN LABMATE.', 'Workstation 9', 'Resolved', 'RAHNUMA KHATOON', '2025-12-16 12:45:00', 0, 0, NULL, NULL, '2025-12-16 11:15:57', '2025-12-16 12:28:10', 0, '8586873925'),
(103, 'Shahana Parveen', 'Marketing', 'Other', 'Other', 'NEW CLINET\r\nPANEL COMPANY- DR CHITRA RAJ CLINIC, GROUP NAME- Dr Chitra Raj & PBPL, PICK UP- DR CHITRA RAJ CLINIC\r\nPLZ UPDATE AUTO PICKUP GENRATE, PICKUP ASSIGNMENTS & AUTO REPORT DELIVERY ALL OTHER', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-16 13:30:00', 0, 0, NULL, NULL, '2025-12-16 12:38:27', '2025-12-16 12:54:50', 0, '8448546358'),
(104, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'KINDLY UPDATE OUR COUNTER PACKAGE CHARGES IN SRI LAXMI NARAYAN MANDIR & LAMABA MEDICAL CENTER PANEL COMANY 20% DISC IN PACKAGE AMOUNT\r\n\r\nANY QUERY CONNECT WITH ME', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-16 13:30:00', 0, 0, NULL, NULL, '2025-12-16 12:39:43', '2025-12-16 13:05:18', 0, '8448546358'),
(105, 'MD ARIF SAIFI', 'Admin', 'Software', 'Labmate', 'PLEASE GIVE PERMISSION OF REPORT PRINT IN LABMATE.', 'Workstation 9', 'Resolved', 'RAHNUMA KHATOON', '2025-12-18 13:00:00', 1, 0, NULL, NULL, '2025-12-16 18:08:43', '2025-12-18 13:27:57', 1, '8586873925'),
(106, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'KINDLY UPDATE SIGN AND STAMP NOTE IN BILL', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-18 15:00:00', 1, 0, NULL, NULL, '2025-12-16 19:33:44', '2025-12-18 15:49:33', 1, '8448546358'),
(107, 'Md Shaquib Alam', 'Other', 'Office Infra', 'AC not cooling', 'KINDLY CHECK & CLEAN LAB ROOM AC FILTERS . COOLING IS TOO LOW DO THE NEEDFUL.', 'Workstation 22', 'Resolved', 'SAHIL BISHT', '2025-12-20 12:30:00', 1, 0, NULL, NULL, '2025-12-16 20:43:22', '2025-12-20 19:01:50', 1, '8448558464'),
(108, 'Ritu Mahalwal', 'Customer Care', 'Office Infra', 'Other', 'water dispenser ( hot ) not working', 'Workstation 29', 'Resolved', 'Ritesh Kumar', '2025-12-17 17:30:00', 0, 0, NULL, NULL, '2025-12-17 10:58:42', '2025-12-17 17:23:20', 0, '9871366002'),
(109, 'Md Shaquib Alam', 'Technical', 'Software', 'Labmate', 'KINDLY MAPPED QUANTIFERON TB GOLD TEST  IN AUTOLUMO WORKSTATION.', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-18 14:00:00', 1, 0, NULL, NULL, '2025-12-17 17:27:41', '2025-12-18 14:04:47', 0, '8448558464'),
(110, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'AUTO REPORTS NOT GONE (MASSH , TRITON , DIYOS , ELANTIS )', 'Workstation 29', 'Resolved', 'RAHNUMA KHATOON', '2025-12-18 13:00:00', 0, 0, NULL, NULL, '2025-12-18 11:26:05', '2025-12-18 12:35:12', 0, '9871366002'),
(111, 'Sanjeet Kumar', 'Customer Care', 'Software', 'Labmate', 'auto whats app report not working', 'Workstation 30', 'Resolved', 'RAHNUMA KHATOON', '2025-12-18 13:00:00', 0, 0, NULL, NULL, '2025-12-18 12:25:45', '2025-12-18 12:35:06', 0, '7982256085'),
(112, 'Shahana Parveen', 'Marketing', 'Software', 'Other software', 'plz provide fix mate user link for ourside lab  centers/ mobile phone etc', NULL, 'Resolved', 'Rohit Bisht', '2025-12-25 20:00:00', 0, 0, NULL, NULL, '2025-12-18 12:48:18', '2025-12-22 14:19:08', 1, '8448546358'),
(113, 'Ritesh Kumar', 'Other', 'Office Infra', 'Other', 'RO MAINTENANCE  MEMORING', 'Workstation 35', 'Resolved', 'Ritesh Kumar', '2025-12-20 16:30:00', 1, 0, NULL, NULL, '2025-12-18 13:24:20', '2025-12-20 16:43:19', 0, '9695983021'),
(114, 'Sanjeet Kumar', 'Customer Care', 'Software', 'Labmate', 'OLD LETTER HAD REPORT', 'Workstation 30', 'Resolved', 'RAHNUMA KHATOON', '2025-12-19 13:00:00', 0, 0, NULL, 'uploads/infra/20251218164937_MSSAKSHICHOUDHARY_23Y_Female_102555599_20251218164752.PDF', '2025-12-18 16:49:37', '2025-12-19 12:05:51', 0, '7982256085'),
(115, 'SAHIL BISHT', 'Other', 'Other', 'Other', 'check', 'Workstation 1', 'Resolved', 'SAHIL BISHT', '2025-12-18 19:00:00', 0, 0, NULL, NULL, '2025-12-18 18:13:06', '2025-12-18 18:16:19', 0, '8057054076'),
(116, 'Shalini Kumari', 'Customer Care', 'Software', 'Labmate', 'NOT ABLE TO OPEN REGISTRATION TAB.', 'Workstation 3', 'Resolved', 'RAHNUMA KHATOON', '2025-12-19 12:00:00', 0, 0, NULL, 'uploads/infra/20251218194701_Capture.PNG', '2025-12-18 19:47:01', '2025-12-19 11:51:42', 0, '9354592130'),
(117, 'Suresh Kundra', 'Customer Care', 'Software', 'ARPRA', 'DR ANITA SABHARWAL OR SABHARWAL CLINIC IS NOT LISTED IN OUR REF BY DROP-LIST. PLEASE ADD SO THAT WE CAN ADD WHILE MAKING BOOKINGS.', 'Workstation 23', 'Resolved', 'RAHNUMA KHATOON', '2026-01-01 15:00:00', 1, 0, NULL, NULL, '2025-12-18 19:54:47', '2026-01-02 12:11:01', 1, '9667798385'),
(118, 'Jyoti Marwah', 'Technical', 'Other', 'Other', 'LEAKAGE FROM AC ( CENTRE)', NULL, 'Resolved', 'Ritesh Kumar', '2025-12-21 18:45:00', 0, 0, NULL, NULL, '2025-12-19 09:26:36', '2025-12-20 16:42:38', 0, '9821189006'),
(119, 'Priyanka Raikwar', 'Technical', 'Hardware', 'Printer/Scanner', 'It does not works properly', 'Workstation 33', 'Resolved', 'Ritesh Kumar', '2025-12-20 17:00:00', 1, 0, NULL, NULL, '2025-12-19 10:12:03', '2025-12-24 19:03:16', 0, '8447623749'),
(120, 'Jaspal singh rawat', 'Customer Care', 'Hardware', 'Telephone', 'TELEPHONE NOT PROPERLY WORKING VERY LOW VOICE', 'Workstation 31', 'Resolved', 'Ritesh Kumar', '2025-12-19 12:45:00', 0, 0, NULL, NULL, '2025-12-19 11:42:39', '2025-12-19 11:57:42', 0, '7838686369'),
(121, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA Neo', 'NURAIN PP COLLECTION NOT SHOWING IN SUMMARY SHEET', 'Workstation 30', 'Resolved', 'SAHIL BISHT', '2025-12-19 14:30:00', 0, 0, NULL, 'uploads/infra/20251219123954_NURAIN_PP.PNG', '2025-12-19 12:39:55', '2025-12-19 14:22:49', 0, '9871366002'),
(122, 'ANKITA', 'Customer Care', 'Other', 'Other', 'Serum ammonia test opened in rg stone pbpl mrp 1000 panel mrp 50% dis 500', 'Workstation 3', 'Resolved', 'ANKITA', '2025-12-19 13:00:00', 0, 0, NULL, NULL, '2025-12-19 12:40:59', '2025-12-19 12:47:15', 0, '8700004157'),
(123, 'Md Shaquib Alam', 'Technical', 'Software', 'Labmate', 'KINDLY UPDATE SAMPLE TYPE IN LEAD TEST EDTA SAMLE.', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-19 14:00:00', 0, 0, NULL, NULL, '2025-12-19 12:46:50', '2025-12-19 13:23:32', 0, '8448558464'),
(124, 'jyoti', 'Customer Care', 'Hardware', 'Other Hardware', 'DERMA MIRACLE PT COLLECTION BOOKED BY ME BUT REFER DOES\" T SHOW IN GROUP\r\nPLEASE ADD REFR IN IT', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-19 13:30:00', 0, 0, NULL, NULL, '2025-12-19 13:16:09', '2025-12-19 13:22:29', 0, '9870554746'),
(125, 'Abhimanyu Singh', 'Marketing', 'Software', 'ARPRA Neo', 'lead system mai 3 se jayada prescription attach krne ka opption de dijiye', NULL, 'Resolved', 'SAHIL BISHT', '2025-12-20 18:00:00', 0, 0, NULL, NULL, '2025-12-19 16:31:35', '2025-12-19 18:40:23', 0, '9971406089'),
(126, 'Abhimanyu Singh', 'Marketing', 'Software', 'Labmate', 'hamare system mai labmate theek se nhi chalta hai', 'Workstation 11', 'Resolved', 'Ritesh Kumar', '2025-12-19 20:00:00', 1, 0, NULL, NULL, '2025-12-19 16:34:15', '2025-12-20 16:41:32', 0, '9971406089'),
(127, 'Gulrez Sultan', 'Technical', 'Office Infra', 'Lights/Fans issue', 'CEILING LIGHT NOT WORKING', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2025-12-19 19:00:00', 0, 0, NULL, 'uploads/infra/20251219164913_GT.jpeg', '2025-12-19 16:49:13', '2025-12-19 18:53:46', 0, '9818247844'),
(128, 'Ritesh Kumar', 'Technical', 'Hardware', 'Other Hardware', 'sample recieving area camera lagana hai', 'Workstation 35', 'Resolved', 'Ritesh Kumar', '2025-12-21 18:45:00', 1, 0, NULL, NULL, '2025-12-19 18:49:28', '2025-12-23 12:05:54', 0, '9695983021'),
(129, 'Ritesh Kumar', 'Technical', 'Hardware', 'Other Hardware', 'purchase new hammer machine', 'Workstation 35', 'Resolved', 'Ritesh Kumar', '2025-12-20 18:45:00', 1, 0, NULL, NULL, '2025-12-19 18:51:18', '2026-01-10 16:46:57', 0, '9695983021'),
(130, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'NEW PANEL COMPANY CREATED  BY THE NAME OF DR RK SOOD &PBPL IN CENTER NO 10 \r\nBILL TO B2B BASIC \r\nCHARGE MODE CREDIT', 'Workstation 3', 'Resolved', 'ANKITA', '2025-12-20 13:00:00', 0, 0, NULL, 'uploads/infra/20251220124537_WhatsApp_Image_2025-12-20_at_12.42.33_PM.jpeg', '2025-12-20 12:45:38', '2025-12-20 12:50:25', 0, '8700004157'),
(131, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'NEW TEST CREATED BY THE NAME OF Tissue for Cytomegalovirus DNA FOR RG STONE EOK \r\nPBPL MRP 10000 AND PANEL MRP 5000 (50%)', 'Workstation 3', 'Resolved', 'ANKITA', '2025-12-20 13:00:00', 0, 0, NULL, NULL, '2025-12-20 12:58:53', '2025-12-20 12:59:45', 0, '8700004157'),
(132, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'NEED TO OPEN TEST CODE (G04, S05, T38) GAD65 IN PANEL Green Park Family Medicine Clinic ON 50% DIS .', 'Workstation 3', 'Resolved', 'ANKITA', '2025-12-20 13:15:00', 0, 0, NULL, NULL, '2025-12-20 13:06:00', '2025-12-20 13:06:43', 0, '8700004157'),
(133, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'TEST OPENED (BLEEDING DISORDER PANEL ) IN NHA PANEL \r\nTEST CODE LB027 , NABL 800/- MRP \r\n                                    NON NABL 680/- MRP', 'Workstation 3', 'Resolved', 'ANKITA', '2025-12-20 13:30:00', 0, 0, NULL, NULL, '2025-12-20 13:23:23', '2025-12-20 13:24:37', 0, '8700004157'),
(134, 'Sanjeet Kumar', 'Customer Care', 'Software', 'ARPRA', 'AUTO PICKUP NOT GENERATE', 'Workstation 30', 'Resolved', 'SAHIL BISHT', '2025-12-20 20:15:00', 0, 0, NULL, NULL, '2025-12-20 15:37:16', '2025-12-20 20:11:36', 0, '7982256085'),
(135, 'Gulrez Sultan', 'Technical', 'Office Infra', 'Electrical issue', 'SWITCH IS NOT WORKING (BACK OFFICE)', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2025-12-24 19:45:00', 1, 0, NULL, 'uploads/infra/20251221073625_BOARD.jpeg', '2025-12-21 07:36:26', '2025-12-26 14:17:43', 1, '9818247844'),
(136, 'Shahana Parveen', 'Marketing', 'Office Infra', 'Other', 'MY TABLE GLASS BROKEN , PLZ FIX IT', 'Workstation 22', 'Resolved', 'Ritesh Kumar', '2025-12-26 19:30:00', 0, 0, NULL, NULL, '2025-12-21 11:51:57', '2025-12-26 18:16:42', 1, '8448546358'),
(137, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA Neo', 'site not working', NULL, 'Resolved', 'SAHIL BISHT', '2025-12-22 12:45:00', 0, 0, NULL, 'uploads/infra/20251222092800_arpara_nuo.PNG', '2025-12-22 09:28:01', '2025-12-22 12:41:32', 0, '9871366002'),
(138, 'Shagun', 'Technical', 'Other', 'Other', 'MASTER MIX ROOM LIGHTS ARE NOT WORKING PROPERLY', 'Workstation 61', 'Resolved', 'Ritesh Kumar', '2025-12-24 19:45:00', 0, 0, NULL, NULL, '2025-12-22 10:48:34', '2025-12-24 19:02:51', 1, '9318474986'),
(139, 'Rohit Bisht', 'Technical', 'Office Infra', 'Chair/Table broken', 'There is no chair at workstation 13 .The that was broken before is no longer there', 'Workstation 13', 'Resolved', 'Ritesh Kumar', '2025-12-24 12:45:00', 0, 0, NULL, NULL, '2025-12-22 11:19:57', '2025-12-24 12:33:17', 1, '8126382045'),
(140, 'SAHIL BISHT', 'Other', 'Other', 'Other', 'check api', NULL, 'Resolved', 'SAHIL BISHT', '2025-12-22 12:45:00', 0, 0, NULL, NULL, '2025-12-22 12:42:51', '2025-12-22 12:43:14', 0, '8057054076'),
(141, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'make new panel company- -DR ABHISHEK SHARMA\r\nCONTACT NO-78380 59557\r\nADDRESS- C-81, LAJPAT NAGAR 2\r\nPRICE LIST- B2B-2NEW, CREDIT\r\nALSO MAKE 2 PACKAGES :\r\n1 ARTHERITIS PROFILE- 2500\r\n2 SURGERY PROFILE- 2000\r\nTEST DETAILS ATTACHED, \r\nANY OTHER QUERY CONNECT WITH ME', NULL, 'Resolved', 'ANKITA', '2025-12-24 15:15:00', 1, 0, NULL, 'uploads/infra/20251222201522_WhatsApp_Image_2025-12-22_at_19.52.49_(1).jpeg', '2025-12-22 20:15:23', '2025-12-25 17:23:39', 1, '8448546358'),
(142, 'Shahana Parveen', 'Marketing', 'Software', 'Other software', 'IN FIX MATE WE CAN ATTCHED ONLY 1 FILE, PLZ ALLOW TO ATTCHED MORE THAN 1', NULL, 'Resolved', 'Rohit Bisht', '2025-12-23 20:00:00', 0, 0, NULL, NULL, '2025-12-22 20:16:19', '2025-12-23 11:39:31', 0, '8448546358'),
(143, 'Rohit Bisht', 'Other', 'Other', 'Other', 'testing multiple attachment', NULL, 'Resolved', 'Rohit Bisht', '2025-12-23 11:45:00', 0, 0, NULL, 'uploads/infra/20251223113858_ee8cc2_Screenshot_2025-01-04_143130.png', '2025-12-23 11:38:59', '2025-12-23 11:39:26', 0, '8126382045'),
(144, 'Shubh Bhatia', 'Technical', 'Software', 'Other software', 'INTERNET NOT WORKING', 'Workstation 20', 'Resolved', 'Ritesh Kumar', '2025-12-23 13:30:00', 0, 0, NULL, NULL, '2025-12-23 12:37:27', '2025-12-23 13:20:02', 0, '8178444947'),
(145, 'Gulrez Sultan', 'Other', 'Hardware', 'Network port/LAN', 'WIFI IS NOT WORKING', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2025-12-23 13:30:00', 0, 0, NULL, NULL, '2025-12-23 12:52:43', '2025-12-23 13:19:27', 0, '9818247844'),
(146, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA', 'rahul ahmed , waqar, anoop,adarsh, sumit chouhan , vikash, waseem , firoz, pustam, abdul kadir , hasan, vijay sigh rawat, gulam nabi, devi lal , zaki, pankaj rana please remove these technician name from home collection assignment list', 'Workstation 29', 'Resolved', 'RAHNUMA KHATOON', '2025-12-24 16:00:00', 0, 0, NULL, NULL, '2025-12-23 15:45:12', '2025-12-24 13:47:00', 0, '9871366002'),
(147, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'AS REFER TO TICKET- #106, YOU UPDATE AS- NHAWL , PLZ ALSO UPDATE HEADER ALSO IN BILLS', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-24 12:30:00', 0, 0, NULL, NULL, '2025-12-23 17:48:07', '2025-12-24 12:15:36', 0, '8448546358'),
(148, 'Dr Vipul Bhasin', 'Other', 'Software', 'Other software', 'Staff List & Logins are not automatically made in Fixmate. Sync with Employee Master is not functional.', NULL, 'Resolved', 'SAHIL BISHT', '2025-12-24 19:00:00', 0, 0, NULL, NULL, '2025-12-23 23:22:46', '2025-12-24 14:43:40', 0, '9810030372'),
(149, 'Ritu Mahalwal', 'Customer Care', 'Software', 'ARPRA', 'NEED LOGIN ID FOR SHADAB ALI (HOMECOLLECTION , ARPARA NEO )', 'Workstation 29', 'Resolved', 'Rohit Bisht', '2025-12-25 14:00:00', 0, 0, NULL, NULL, '2025-12-24 13:29:33', '2025-12-24 19:03:45', 0, '9871366002'),
(150, 'shama', 'Technical', 'Hardware', 'Monitor issue', 'IVD PCR IS NOT WORKING', 'Workstation 61', 'Resolved', 'Ritesh Kumar', '2025-12-25 19:30:00', 1, 0, NULL, NULL, '2025-12-24 14:59:28', '2025-12-26 14:18:18', 0, '9758109554'),
(151, 'SAHIL BISHT', 'Admin', 'Office Infra', 'Housekeeping/cleaning', 'I need a dustbin here because there is garbage from paper, tissues, and wrappers here. Therefore, we need a trash can here, please provide it as soon as possible.', 'Workstation 13', 'Resolved', 'Ritesh Kumar', '2026-01-01 18:45:00', 1, 0, NULL, NULL, '2025-12-25 13:48:07', '2026-01-01 18:45:09', 1, '8057054076'),
(152, 'Suresh Kundra', 'Customer Care', 'Software', 'ARPRA', 'CHILD & ORTHO CLINIC IS COMING IN APPRA IN REFERRED BY DROP-DOWN LIST.', 'Workstation 31', 'Resolved', 'RAHNUMA KHATOON', '2025-12-29 15:00:00', 0, 0, NULL, NULL, '2025-12-25 16:35:14', '2025-12-27 16:31:33', 1, '9667798385'),
(153, 'shama', 'Technical', 'Hardware', 'Monitor issue', 'IVD PCR IS NOT WORKING', 'Workstation 61', 'In Progress', 'SAHIL BISHT', '2026-01-07 14:15:00', 1, 0, NULL, NULL, '2025-12-24 14:59:28', '2026-01-07 16:01:53', 0, '9758109554'),
(154, 'Gulrez Sultan', 'Other', 'Office Infra', 'Lights/Fans issue', 'HANGING LIGHT IN SAMPLE COLLECTION ROOM IS NOT WORKING', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2025-12-26 14:30:00', 0, 0, NULL, 'uploads/infra/20251226112827_c615a6_COLLECTION_ROOM.jpeg', '2025-12-26 11:28:27', '2025-12-26 14:18:48', 0, '9818247844'),
(155, 'Suresh Kundra', 'Customer Care', 'Other', 'Other', 'PLEASE PULL THE REPORT OF AMBIKA FROM 23/MAR/25. PLZ TRY FEW DATES BEFORE & AFTER GIVEN DATE.', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-29 16:00:00', 0, 0, NULL, NULL, '2025-12-26 12:35:58', '2025-12-27 13:49:42', 0, '9667798385'),
(156, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'Kindly allow access to my Labmate ID to create a new bill category.', 'Workstation 2', 'Resolved', 'RAHNUMA KHATOON', '2025-12-27 16:00:00', 1, 0, NULL, 'uploads/infra/20251226162031_7f2f76_WhatsApp_Image_2025-12-26_at_4.20.00_PM.jpeg', '2025-12-26 16:20:32', '2025-12-27 16:28:10', 0, '8700004157'),
(157, 'SONA', 'Customer Care', 'Office Infra', 'Chair/Table broken', '.', 'Workstation 28', 'Resolved', 'Ritesh Kumar', '2025-12-27 15:45:00', 0, 0, NULL, NULL, '2025-12-27 08:37:52', '2025-12-27 15:35:03', 0, '8076741165'),
(158, 'MD ARIF SAIFI', 'Admin', 'Hardware', 'CPU', 'My system is not working properly, continuously showing error and auto shut down.', 'Workstation 9', 'Resolved', 'Ritesh Kumar', '2025-12-30 18:00:00', 0, 0, NULL, 'uploads/infra/20251227115530_5243ad_WhatsApp_Image_2025-12-27_at_11.53.19_AM.jpeg', '2025-12-27 11:55:31', '2025-12-30 16:08:38', 0, '8586873925'),
(159, 'Ritu Mahalwal', 'Technical', 'Office Infra', 'Other', 'PARKING (BASEMENT LIFT) \'S BUTTON IS NOT WORKING IN LIFT', NULL, 'Resolved', 'Ritesh Kumar', '2025-12-29 19:00:00', 0, 0, NULL, NULL, '2025-12-27 16:24:37', '2025-12-28 16:45:07', 0, '9871366002'),
(160, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'URINE MYOGLOBIN TEST OPENED IN PANEL BANARSIDAS CHANDIWALA HOSPITAL \r\nTOTAL MRP 1500 AND DISCOUNTED AMOUNT 900/- (40%) DISCOUNT ALLOWED', 'Workstation 47', 'Resolved', 'ANKITA', '2025-12-27 17:00:00', 0, 0, NULL, NULL, '2025-12-27 16:50:44', '2025-12-27 16:51:22', 0, '8700004157'),
(161, 'Monika Rajput', 'Technical', 'Hardware', 'Monitor issue', 'System not working properly, getting hang in between', 'Workstation 16', 'Resolved', 'Ritesh Kumar', '2025-12-27 18:45:00', 0, 0, NULL, NULL, '2025-12-27 17:55:34', '2025-12-27 18:42:03', 0, NULL),
(162, 'Sanjeet Kumar', 'Customer Care', 'Software', 'Other software', 'AUTO PICKUP NOT GENERATE', 'Workstation 30', 'Resolved', 'SAHIL BISHT', '2025-12-29 12:15:00', 0, 0, NULL, NULL, '2025-12-28 15:57:25', '2025-12-29 12:01:47', 0, '7982256085'),
(163, 'Jaspal singh rawat', 'Other', 'Hardware', 'Other Hardware', 'KINDLY SWITCHED OFF AC FOR WHOLE NIGHT ITS TO COLD', 'Workstation 1', 'Resolved', 'SAHIL BISHT', '2025-12-29 18:15:00', 0, 0, NULL, NULL, '2025-12-29 08:29:32', '2025-12-29 18:07:17', 0, '7838686369'),
(164, 'Jaspal singh rawat', 'Technical', 'Hardware', 'Other Hardware', 'Sir the AC was supposed to be turned on between 2 and 3 but it\'s been running from 2 AM to 7 AM', 'Workstation 1', 'Resolved', 'SAHIL BISHT', '2025-12-29 18:15:00', 0, 0, NULL, NULL, '2025-12-29 08:32:31', '2025-12-29 18:07:05', 0, '7838686369'),
(165, 'Jaspal singh rawat', 'Customer Care', 'Software', 'Labmate', 'MY ID OPEN IN 19 NO ID SHEETLA', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-29 14:30:00', 0, 0, NULL, NULL, '2025-12-29 08:33:22', '2025-12-29 12:37:44', 0, '7838686369'),
(166, 'Suresh Kundra', 'Customer Care', 'Other', 'Other', 'PATIENT NAME: YASH RAJ SINGH, POSSIBLE DATE: 05/NOV/22. KINDLY TRY FEW DATES BEFORE & AFTER OF MENTIOEND DATE. NEED TO PULL REPORT OF BIOPSY.', 'Workstation 23', 'Resolved', 'RAHNUMA KHATOON', '2025-12-31 16:00:00', 0, 0, NULL, NULL, '2025-12-29 12:59:47', '2025-12-29 13:10:44', 0, '9667798385'),
(167, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'MAKE NEW PANEL COMAPNY AS MEDIWAORLD NOIDA, INDRAPURAM, SUKHDEV VIHAR SAME AS MEDIWORLD FERTICITY\r\n\r\nALSO MAKE NEW PICKUP NEW GROUP\r\nDO AUTO PICK UP GENERATE, PICK UP ASSIGNEMNTS, AUTO REPORT SENDING\r\n\r\nALL DETAILS CANTACT PERSON NO I WILL SHARE U - ALSO UPDATE SAME TO ANKITA', NULL, 'In Progress', 'SAHIL BISHT', '2026-01-01 18:15:00', 1, 0, NULL, NULL, '2025-12-29 17:23:54', '2026-01-01 18:41:14', 0, '8448546358'),
(168, 'Maria Dass', 'Customer Care', 'Software', 'Labmate', 'pls open all  pkgs in panal company  Goswami home medical', 'Workstation 2', 'Resolved', 'ANKITA', '2025-12-30 15:00:00', 0, 0, NULL, NULL, '2025-12-30 12:14:25', '2025-12-30 14:57:04', 0, '9654876714'),
(169, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'NEED LABMATE ID FOR SHADAB ALI , CONT NO -7088882153', 'Workstation 29', 'Resolved', 'SAHIL BISHT', '2026-01-02 17:30:00', 0, 0, NULL, NULL, '2025-12-30 13:07:42', '2026-01-02 15:34:18', 0, '9871366002'),
(170, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Other software', 'PLEASE REMOVE KOMAL, SONU, NISHA, MUIN AND SHUBH FROM PETPOOJA PAYROLL', NULL, 'Resolved', 'Dr Vipul Bhasin', '2025-12-31 15:00:00', 0, 0, NULL, NULL, '2025-12-30 14:48:53', '2025-12-31 14:16:28', 0, '9871366002'),
(171, 'Akash yadav', 'Customer Care', 'Software', 'Labmate', 'REPORT SENDING ERRORS.', 'Workstation 25', 'Rejected', NULL, NULL, 0, 1, 'Can\'t understand the ticket only!', NULL, '2025-12-30 17:40:39', '2025-12-31 13:41:34', 0, '9899847571'),
(172, 'Sanjeet Kumar', 'Customer Care', 'Software', 'Labmate', 'REPORT NOT WORKING MANUALLY', 'Workstation 30', 'Resolved', 'Dr Vipul Bhasin', '2025-12-31 13:45:00', 0, 0, NULL, 'uploads/infra/20251230175749_e2af59_REPORT__NO_WORKING.pdf', '2025-12-30 17:57:49', '2025-12-31 13:41:10', 0, '7982256085'),
(173, 'MD ARIF SAIFI', 'Admin', 'Hardware', 'CPU', 'CPU INSTALLED SUCCESSFULLY. BUT THERE IS NO LABMATE, BUSY SOFT, MS OFFICE, ALL IN ONE.', 'Workstation 9', 'Resolved', 'SAHIL BISHT', '2025-12-31 16:00:00', 0, 0, NULL, NULL, '2025-12-30 18:03:12', '2025-12-31 15:33:52', 0, '8586873925'),
(174, 'Md Shaquib Alam', 'Other', 'Office Infra', 'Other', 'HAEMATOLOGY WATER TAP IS OVER FLOW DUE TO BLOCKAGE PLEASE DO THE NEEDFULL ASAP', 'Workstation 53', 'Resolved', 'Ritesh Kumar', '2026-01-03 19:15:00', 1, 0, NULL, NULL, '2025-12-30 19:22:00', '2026-01-14 11:28:32', 1, '8448558464'),
(175, 'Md Shaquib Alam', 'Other', 'Office Infra', 'Other', 'LAB TESTING AREA WASHROOM TAP IS NOT WORKING AND SOAP DISPENSER ALSO NOT WORKING PLEASE DO THE NEEDFULL....', 'Workstation 54', 'Resolved', 'Ritesh Kumar', '2026-01-03 19:45:00', 1, 0, NULL, NULL, '2025-12-30 19:23:27', '2026-01-06 15:56:06', 1, '8448558464'),
(176, 'Ritu Mahalwal', 'Home Collection', 'Software', 'Other software', 'HOMECOLLECTION AAP NOT WORKING', NULL, 'Resolved', 'RAHNUMA KHATOON', '2025-12-31 16:00:00', 0, 0, NULL, NULL, '2025-12-31 11:42:03', '2025-12-31 15:02:43', 0, '9871366002'),
(177, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'AUTO REPORTS NOT GONE IN GRIOU', NULL, 'Resolved', 'Dr Vipul Bhasin', '2025-12-31 14:15:00', 0, 0, NULL, 'uploads/infra/20251231120356_740a28_FAILED_REPORT.PNG', '2025-12-31 12:03:56', '2025-12-31 13:38:24', 0, '9871366002'),
(178, 'Md Shaquib Alam', 'Other', 'Office Infra', 'AC not cooling', 'LAB ROOM AC NOT COOLING', 'Workstation 51', 'Resolved', 'SAHIL BISHT', '2026-01-01 17:15:00', 0, 0, NULL, NULL, '2025-12-31 12:42:17', '2026-01-01 17:06:24', 1, '8448558464'),
(179, 'shama', 'Other', 'Hardware', 'CPU', 'IVD PCR SYSTEM IS NOT WORKING PROPERLY', 'Workstation 61', 'Resolved', 'Ritesh Kumar', '2026-01-04 13:00:00', 1, 0, NULL, NULL, '2026-01-01 19:12:24', '2026-01-05 14:20:45', 1, '9758109554'),
(180, 'Shalini rawat', 'Technical', 'Software', 'Labmate', 'PANEL COMPANY -SENIOR CITIZEN -PAYMENT MODE (PHONE PAY) IS NOT AVAILABLE', NULL, 'Resolved', 'RAHNUMA KHATOON', '2026-01-03 14:00:00', 0, 0, NULL, NULL, '2026-01-02 13:42:55', '2026-01-02 13:50:56', 0, '9650692437'),
(181, 'SALEEM JAVED', 'Admin', 'Software', 'Labmate', 'Payment mode \"phone pe\" now showing in many company (SPECIAL PBPL, VISTA PBPL, PLATENIUM PBPL, SILVER PBPL , GOLD PBPL AND SENIOR CITIZEN PBPL PLUS )', 'Workstation 3', 'Resolved', 'Rohit Bisht', '2026-01-02 14:45:00', 0, 0, NULL, NULL, '2026-01-02 14:31:29', '2026-01-02 14:38:39', 0, '9654441851'),
(182, 'Gulrez Sultan', 'Customer Care', 'Software', 'Labmate', 'NOT ABLE TO SETTLED THE AMOUNT BY PHONE PE / THERE MORE COMPANY ALSO KINDLY CHECK - \r\n1. SENIOR CITIZEN PBPL PLUS\r\n2. SILVER PBPL PLUS\r\n3. GOLD PBPL PLUS BILL CATEGORY\r\n4. PLATINUM PBPL PLUS\r\n5. VISTA PBPL PLUS\r\n6. SPECIAL PBPL PLUS\r\n7. AVON DIAGNOSTIC\r\n8. Goswami Home Medical Services \r\n9. CRYSTA IVF\r\nDelhi University\r\nDR PODDAR CLINIC\r\nFEMME CARE CLINIC\r\nJYOTI KIRAN KOHLI CLINIC\r\nAASTHA MEDICAL CENTRE,', 'Workstation 1', 'Resolved', 'Rohit Bisht', '2026-01-02 15:00:00', 0, 0, NULL, 'uploads/infra/20260102143334_43bddb_PHONE_PE_02-01-2026.JPG', '2026-01-02 14:33:34', '2026-01-02 14:41:33', 0, '9818247844');
INSERT INTO `infra_tickets` (`ticket_id`, `created_by`, `department`, `category`, `subcategory`, `description`, `workstation`, `status`, `assigned_to`, `commitment_time`, `is_delayed_pick`, `is_invalid`, `invalid_reason`, `image_path`, `created_at`, `updated_at`, `reminder_sent`, `contact`) VALUES
(183, 'Shalini rawat', 'Technical', 'Software', 'Labmate', 'PANEL COMPANY -NUBIRTH GYNAECOLOGY AND WOMEN HEALTH CLINIC PAYMENT MODE ONLY CASH SHOWING NO OTHER RECIPET MODE IS SHOWING', NULL, 'Resolved', 'Rohit Bisht', '2026-01-02 17:45:00', 0, 0, NULL, NULL, '2026-01-02 17:28:18', '2026-01-02 17:36:51', 0, '9650692437'),
(184, 'DISHIKA', 'Center Phlebo', 'Software', 'Labmate', 'SCI IVF GK-1 online report portal is not working since the last two days. Reports are not opening. Please check and resolve.', NULL, 'Resolved', 'Ritesh Kumar', '2026-01-04 14:00:00', 1, 0, NULL, NULL, '2026-01-03 11:07:54', '2026-01-05 17:12:59', 0, '8595614476'),
(185, 'SALEEM JAVED', 'Admin', 'Software', 'Labmate', 'PHONE PE NOT SHOWING IN COMPANY \"SERVICE CHARGES\"', 'Workstation 3', 'Resolved', 'RAHNUMA KHATOON', '2026-01-03 19:30:00', 0, 0, NULL, NULL, '2026-01-03 14:52:43', '2026-01-03 19:15:33', 0, '9654441851'),
(186, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'KINDLY CHANGE DENGUE NS1 ANTIGEN CHARGES AS 1000/ ALLOWED 50% DISC IN SVASTHAM PANEL COMAPNY\r\nTEST CODE- G04S03T16', NULL, 'Resolved', 'ANKITA', '2026-01-09 10:00:00', 0, 0, NULL, NULL, '2026-01-03 20:31:07', '2026-01-09 09:51:49', 1, '8448546358'),
(187, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', '3RD EVENING AUTO REPORTS NOT GONE', 'Workstation 29', 'Resolved', 'RAHNUMA KHATOON', '2026-01-05 12:45:00', 0, 0, NULL, NULL, '2026-01-04 12:10:01', '2026-01-05 12:40:34', 1, '9871366002'),
(188, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Other software', 'PLEASE REMOVE MASHROOR AND SHUBH BHATIA FROM PET POOJA', 'Workstation 29', 'Resolved', 'Dr Vipul Bhasin', '2026-01-05 18:00:00', 0, 0, NULL, NULL, '2026-01-04 16:09:31', '2026-01-05 17:47:50', 1, '9871366002'),
(189, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'MAKE A NEW PANEL COMPANY AS ASTHA CAMP \r\nBILLING CATEGORY- B2B BASIC (CREDIT)\r\nGROUP NAME IS ASTHA MEDUCAL CENTER & PBPL', NULL, 'Resolved', 'ANKITA', '2026-01-05 08:45:00', 0, 0, NULL, NULL, '2026-01-04 16:58:36', '2026-01-05 08:32:38', 0, '8448546358'),
(190, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'i\'m not able to make receipt of back date kindly check', 'Workstation 1', 'Resolved', 'RAHNUMA KHATOON', '2026-01-05 12:45:00', 0, 0, NULL, 'uploads/infra/20260105083506_d921b6_WhatsApp_Image_2026-01-05_at_8.31.51_AM.jpeg', '2026-01-05 08:35:06', '2026-01-05 12:38:14', 0, '8700004157'),
(191, 'Sanjeet Kumar', 'Customer Care', 'Software', 'Labmate', 'REPORT AUTO WHATS APP  NOT WORKING   \r\nYESTERDAY NIGHT  REPORT  OR  TODAY', 'Workstation 30', 'Resolved', 'RAHNUMA KHATOON', '2026-01-05 14:30:00', 0, 0, NULL, 'uploads/infra/20260105120558_accafd_REPORT.PNG', '2026-01-05 12:05:58', '2026-01-05 12:35:44', 0, '7982256085'),
(192, 'Priyanka Raikwar', 'Other', 'Software', 'Labmate', 'NOT ABLE TO DOWNLOAD ONLY THIS DATE PATIENT 29/12/2025 PATIENT ID 102558115', 'Workstation 33', 'Resolved', 'RAHNUMA KHATOON', '2026-01-07 16:00:00', 1, 0, NULL, NULL, '2026-01-05 12:59:33', '2026-01-10 15:00:32', 0, '8447623749'),
(193, 'Sanjeet Kumar', 'Customer Care', 'Software', 'Labmate', 'AUTO WHATS APP  REPORT NOT WORKING', 'Workstation 30', 'Resolved', 'RAHNUMA KHATOON', '2026-01-05 15:00:00', 1, 0, NULL, 'uploads/infra/20260105133324_79137c_REPORT.PNG', '2026-01-05 13:33:25', '2026-01-10 15:00:52', 0, '7982256085'),
(194, 'Dr Vipul Bhasin', 'Other', 'Hardware', 'Other Hardware', 'Multiple cameras are not working!', NULL, 'In Progress', 'Ritesh Kumar', '2026-01-06 16:15:00', 1, 0, NULL, NULL, '2026-01-05 14:20:04', '2026-01-07 11:21:57', 0, '9810030372'),
(195, 'Shadab Ali', 'Home Collection', 'Software', 'Other software', 'i want excel in my system', NULL, 'Resolved', 'Dr Vipul Bhasin', '2026-01-05 18:00:00', 0, 0, NULL, NULL, '2026-01-05 14:58:45', '2026-01-05 17:46:53', 0, NULL),
(196, 'Shahana Parveen', 'Marketing', 'Software', 'ARPRA Neo', 'We would like to have more options in the ticketing system, where a ticket can be assigned to a specific person who will be only responsible for the work', NULL, 'Resolved', 'Dr Vipul Bhasin', '2026-01-05 18:30:00', 0, 0, NULL, 'uploads/infra/20260105154858_3254c3_WhatsApp_Image_2026-01-05_at_15.44.46.jpeg', '2026-01-05 15:48:58', '2026-01-05 17:46:04', 0, '8448546358'),
(197, 'Md Shaquib Alam', 'Technical', 'Hardware', 'CPU', 'CPU NOT WORKING', 'Workstation 51', 'Resolved', 'Ritesh Kumar', '2026-01-05 19:45:00', 0, 0, NULL, NULL, '2026-01-05 18:57:03', '2026-01-05 19:23:14', 0, '8448558464'),
(198, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'alredy have the permission to make and modify 60days before receipt but not able now\r\nplz do needfull', NULL, 'Resolved', 'RAHNUMA KHATOON', '2026-01-06 14:45:00', 0, 0, NULL, NULL, '2026-01-06 12:31:35', '2026-01-06 14:35:20', 0, '8448546358'),
(199, 'Md Shaquib Alam', 'Technical', 'Office Infra', 'AC not cooling', 'LAB ROOM AC NOT COOLING PROPERLY', 'Workstation 52', 'Resolved', 'Ritesh Kumar', '2026-01-10 17:00:00', 0, 0, NULL, NULL, '2026-01-07 14:02:27', '2026-01-10 16:47:09', 1, '8448558464'),
(200, 'Ritu Mahalwal', 'Customer Care', 'Office Infra', 'Other', 'water dispenser not working (hot side )', 'Workstation 29', 'Resolved', 'Ritesh Kumar', '2026-01-10 19:30:00', 0, 0, NULL, NULL, '2026-01-08 10:12:47', '2026-01-09 15:28:39', 0, '9871366002'),
(201, 'Gulrez Sultan', 'Customer Care', 'Software', 'Labmate', 'KINDLY OPEN THE PAYMENT OPTIONS - CREDIT CARD + PHONE PE', 'Workstation 1', 'Resolved', 'Dr Vipul Bhasin', '2026-01-11 02:15:00', 0, 0, NULL, 'uploads/infra/20260108150250_f8bcca_SCARLET_CLINIC.JPG', '2026-01-08 15:02:51', '2026-01-11 00:52:32', 1, '9818247844'),
(202, 'ANKITA', 'Customer Care', 'Software', 'Labmate', 'ALL MEDIWORLD PANEL COMPANY NEED TO BE OPENED IN CENTER NO 15.', 'Workstation 47', 'Resolved', 'ANKITA', '2026-01-09 09:45:00', 0, 0, NULL, NULL, '2026-01-08 15:24:04', '2026-01-09 09:41:20', 0, '8700004157'),
(203, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'MAKE A NEW PANEL COMPANY \r\nDETAILS ATTCHED REPORTS DELIVERY ON MAIL MANDATORY\r\nemail: babysoonindia@gmail.com \r\nmake a group by the name of BABY SOON IVF & PBPL\r\nPICK UP NAME- BABYSOON IVF KAROL BAGH\r\nALSO DO ALL PRIMARY ASSIGNMENTS LIKE SAMPLE PICKUP, ASSIGNMNTS AND REPORT DELIVERY IN GROUP', NULL, 'Resolved', 'ANKITA', '2026-01-09 15:00:00', 1, 0, NULL, 'uploads/infra/20260108172921_180cf3_WhatsApp_Image_2026-01-08_at_17.24.52.jpeg', '2026-01-08 17:29:21', '2026-01-10 14:50:58', 0, '8448546358'),
(204, 'Akshay Kumar Ram', 'House Keeping', 'Office Infra', 'Other', 'DISPENSER ME HOT WATER NAHI AA RAHA 1 WEEKSE BAS', 'Workstation 19', 'Resolved', 'Ritesh Kumar', '2026-01-09 15:30:00', 0, 0, NULL, NULL, '2026-01-08 19:43:41', '2026-01-09 15:28:24', 0, '9958547534'),
(205, 'SONA', 'Customer Care', 'Software', 'ARPRA Neo', 'RESOLVE OPTION IS NOT COMING', NULL, 'Resolved', 'Dr Vipul Bhasin', '2026-01-10 16:00:00', 0, 0, NULL, 'uploads/infra/20260109093559_346025_TICKET_2.JPG', '2026-01-09 09:36:00', '2026-01-10 14:45:28', 1, '8076741165'),
(206, 'Jaspal singh rawat', 'Customer Care', 'Software', 'Labmate', 'NOT ABLE TO SHARE TRITON IPD BILL KINDLY GIVE AUTHORITY', 'Workstation 1', 'Resolved', 'RAHNUMA KHATOON', '2026-01-12 15:00:00', 0, 0, NULL, NULL, '2026-01-10 08:50:36', '2026-01-10 15:09:08', 0, '7838686369'),
(207, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'AUTO REPORTS NOT GONE', 'Workstation 29', 'Resolved', 'RAHNUMA KHATOON', '2026-01-12 16:00:00', 0, 0, NULL, NULL, '2026-01-10 10:06:08', '2026-01-10 15:01:06', 0, '9871366002'),
(208, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'NOT ABLE TO SELECT TEST ON ESTIMATION', 'Workstation 29', 'Resolved', 'RAHNUMA KHATOON', '2026-01-12 16:00:00', 1, 0, NULL, 'uploads/infra/20260110102758_264dd9_CAP.PNG', '2026-01-10 10:27:59', '2026-01-13 15:35:09', 0, '9871366002'),
(209, 'Gulrez Sultan', 'Customer Care', 'Software', 'Labmate', 'KINDLY MAKE TEST PACKAGE FOR SCARLET CLINIC', 'Workstation 1', 'Rejected', NULL, NULL, 0, 1, 'Need More Details to act', NULL, '2026-01-10 11:17:34', '2026-01-10 14:38:47', 0, '9818247844'),
(210, 'ANKITA', 'Other', 'Other', 'Other', 'CHAIR IS BROKEN KINDLY REPLACE IT.', 'Workstation 47', 'Resolved', 'Ritesh Kumar', '2026-01-10 19:45:00', 1, 0, NULL, NULL, '2026-01-10 13:19:34', '2026-01-11 12:47:24', 0, '8700004157'),
(211, 'Shahana Parveen', 'Marketing', 'Software', 'Labmate', 'MAKE A NEW PANLE COMPANY AS \"BLOOM IVF\" IN CENTER ID-10, BILLING CATEGORY- STD MRP, PAYING \r\nGROUP NAME- BLOOM IVF & PBPL\r\nPICKUP NAME- Fortis La Femme (BLOOM IVF)\r\nAND DO ALL ASSIGNMENTS, PICK UP GENERATE, SSIGNMENTS, REPORT DELIVERY\r\n\r\nKINDLY DO ON PRIORITY', NULL, 'In Progress', 'ANKITA', '2026-01-10 23:45:00', 1, 0, NULL, NULL, '2026-01-10 14:42:28', '2026-01-11 00:13:33', 0, '8448546358'),
(212, 'Jaspal singh rawat', 'Customer Care', 'Software', 'Labmate', 'REPORTS OLDER THAN 3 MONTHS DO NOT SHOW IN MY ID & IM ALSO UNABLE TO SHARE THE REPORTS', 'Workstation 2', 'Resolved', 'Dr Vipul Bhasin', '2026-01-11 02:00:00', 0, 0, NULL, NULL, '2026-01-11 00:33:02', '2026-01-11 00:45:41', 0, '7838686369'),
(213, 'AMAN CHOTALA', 'Customer Care', 'Software', 'Labmate', 'Reports older than 3 months do not show in my ID and I am also unable to share the reports', 'Workstation 1', 'Resolved', 'Dr Vipul Bhasin', '2026-01-11 02:00:00', 0, 0, NULL, NULL, '2026-01-11 00:33:43', '2026-01-11 00:45:16', 0, '9773552558'),
(214, 'Dr Vipul Bhasin', 'Customer Care', 'Software', 'Labmate', '@Rahnuma\r\nWe are not able to add Whatsapp GroupID in labmate Panel Company as it is not allowing more than 10 Digits! Hence we are unable to register AutoWhatsApp to new clients!\r\nNeed urgent solution for the same!', NULL, 'Resolved', 'RAHNUMA KHATOON', '2026-01-12 16:00:00', 0, 0, NULL, NULL, '2026-01-11 00:49:05', '2026-01-12 15:58:23', 1, '9810030372'),
(215, 'Dr Vipul Bhasin', 'Customer Care', 'Software', 'ARPRA Neo', '@Sahil\r\nInside daily summary of ARPRA Neo which comes on Whatsapp, Daily Call Summary is grossly inaccurate. No data, be it Total Calls, Completed calls or missed calls matches data of the software UI. Please correct this error/discuss with me why this issue is coming!', NULL, 'New', NULL, NULL, 0, 0, NULL, NULL, '2026-01-11 01:00:48', '2026-01-12 01:52:09', 1, '9810030372'),
(216, 'Gulrez Sultan', 'Technical', 'Office Infra', 'Other', 'KINDLY TURN OFF THE AC AT GROUND FLOOR', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2026-01-11 13:00:00', 0, 0, NULL, NULL, '2026-01-11 12:34:40', '2026-01-11 12:47:10', 0, '9818247844'),
(217, 'Gulrez Sultan', 'Customer Care', 'Software', 'Labmate', 'KINDLY OPEN THE PHONE PE OPTION', 'Workstation 1', 'Resolved', 'RAHNUMA KHATOON', '2026-01-12 16:15:00', 0, 0, NULL, 'uploads/infra/20260111152229_7e3d93_TRITON.JPG', '2026-01-11 15:22:29', '2026-01-12 16:00:46', 1, '9818247844'),
(218, 'Gulrez Sultan', 'Customer Care', 'Office Infra', 'Other', 'REMINDER - 2 KINDLY REDUCE THE AC COOLING / CLOSE THE AC', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2026-01-12 17:15:00', 0, 0, NULL, NULL, '2026-01-12 10:11:23', '2026-01-12 17:05:31', 0, '9818247844'),
(219, 'Shalini rawat', 'Technical', 'Software', 'Labmate', 'WHILE BOOKING VIRAL MARKERS NO POP UP IS SHOWING FOR CLIA PLEASE RESOLVE THE PROBLEM', NULL, 'New', NULL, NULL, 0, 0, NULL, NULL, '2026-01-12 19:03:24', '2026-01-13 19:19:33', 1, '9650692437'),
(220, 'Dr Vipul Bhasin', 'Other', 'Software', 'Other software', '@Rahnuma\r\nPlease disable to Old Hiccup module first thing tomorrow morning as the new module is now running. Do send me details of all or any hiccup which would have got made on the 13th Jan 2026.\r\nAlso note that the new hiccups module has been merged with Infra Ticketing now.', 'Workstation 1', 'Resolved', 'RAHNUMA KHATOON', '2026-01-13 15:45:00', 0, 0, NULL, NULL, '2026-01-12 21:17:42', '2026-01-13 15:36:48', 0, '9810030372'),
(221, 'Gulrez Sultan', 'Technical', 'Office Infra', 'Lights/Fans issue', 'LIGHT ISSUES  - \r\n1. PATRIOTIC ROOM \r\n2. LOBBY', 'Workstation 1', 'Resolved', 'Ritesh Kumar', '2026-01-13 15:00:00', 1, 0, NULL, 'uploads/infra/20260113132855_9a8336_WhatsApp_Image_2026-01-13_at_1.24.48_PM.jpeg', '2026-01-13 13:28:55', '2026-01-14 11:28:16', 0, '9818247844'),
(222, 'SALEEM JAVED', 'Customer Care', 'Software', 'Labmate', 'Payment mode \"STAFF RECEIPT \" Not showing in company \"SPECIAL PBPL\"', 'Workstation 3', 'Resolved', 'RAHNUMA KHATOON', '2026-01-13 15:45:00', 0, 0, NULL, NULL, '2026-01-13 13:37:38', '2026-01-13 15:36:35', 0, '9654441851'),
(223, 'ANKITA', 'Other', 'Software', 'Labmate', 'KINDLY CREATE LABMATE ID FOR DATA ENTRY  NISHU AND VIKRAM \r\n1) NISHU=7820074697\r\n2) VIKRAM =9871177543', 'Workstation 47', 'Resolved', 'RAHNUMA KHATOON', '2026-01-13 17:00:00', 0, 0, NULL, NULL, '2026-01-13 15:54:39', '2026-01-13 16:01:21', 0, '8700004157'),
(224, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Other software', 'PLEASE REMOVE SHALINI AND SALMAN NAME FROM PETPOOJA', 'Workstation 29', 'New', NULL, NULL, 0, 0, NULL, NULL, '2026-01-13 16:01:54', '2026-01-14 16:08:48', 1, '9871366002'),
(225, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'LAB NO 102510060970 PLEASE SEE COMPARATIVE REPORT RESULT OF URINE SAMPLE ,', 'Workstation 29', 'New', NULL, NULL, 0, 0, NULL, NULL, '2026-01-13 16:03:11', '2026-01-14 16:08:48', 1, '9871366002'),
(226, 'Ritu Mahalwal', 'Customer Care', 'Software', 'Labmate', 'PLEASE CREATE LOGIN ID FOR LABMATE AND ARPARA STAFF NAME KHUSHIYA KHAN', 'Workstation 29', 'In Progress', 'RAHNUMA KHATOON', '2026-01-15 18:45:00', 0, 0, NULL, NULL, '2026-01-13 16:06:08', '2026-01-14 18:42:37', 1, '9871366002'),
(227, 'Akshay Kumar Ram', 'House Keeping', 'Other', 'Other', 'The water dispenser is malfunctioning; hot water is not being dispensed.”\r\n	•	“The hot water function of the water dispenser is not working.” basement area.', 'Workstation 19', 'In Progress', 'Ritesh Kumar', '2026-01-15 18:30:00', 0, 0, NULL, NULL, '2026-01-13 19:47:33', '2026-01-14 11:27:52', 0, '9958547534'),
(228, 'Akshay Kumar Ram', 'House Keeping', 'Other', 'Other', '(1) Parking area ke guard room ki light kharab hai. Kripya ise jald se jald theek karwane ki \r\n     vyavastha ki jaaye\r\n(2)  The vacuum machine is not working. I need to get it repaired', 'Workstation 19', 'In Progress', 'Ritesh Kumar', '2026-01-15 10:45:00', 0, 0, NULL, NULL, '2026-01-13 20:22:06', '2026-01-14 11:27:26', 0, '9958547534'),
(229, 'Ritu Mahalwal', 'Customer Care', 'Office Infra', 'Other', 'WATER DISPENSER NOT WORKING ( HOT SIDE )', 'Workstation 29', 'New', NULL, NULL, 0, 0, NULL, NULL, '2026-01-14 15:36:05', '2026-01-14 15:36:05', 0, '9871366002'),
(230, 'Ritu Mahalwal', 'Customer Care', 'Office Infra', 'Other', 'EXHAUST FAN NOT WORKING NEAR CCG', 'Workstation 29', 'New', NULL, NULL, 0, 0, NULL, NULL, '2026-01-14 16:21:23', '2026-01-14 16:21:23', 0, '9871366002'),
(231, 'Shahana Parveen', 'Marketing', 'Software', 'ARPRA', 'GROUP NAME- Janta Clinic & PBPL\r\nPANEL COMPANY- JANTA CLINIC\r\nPICK UP NAME- JANTA CLINIC\r\n\r\nKINDLY DO ALL ASSIGNMENTS- AUTO PICK UP GENERATE, ASSIGNMENT AND AUTO WHATSAPP DELIVERY', NULL, 'Resolved', 'RAHNUMA KHATOON', '2026-01-14 18:45:00', 0, 0, NULL, NULL, '2026-01-14 18:21:48', '2026-01-14 18:42:18', 0, '8448546358'),
(232, 'Aman Shukla', 'Field', 'Software', 'ARPRA Neo', 'ASSIGNMENT KE MSG GROUP ME MSG NHI JA RAHE HAI PLEASE CHECK MAAM   AUTO WHATSAPP AND  AUTO ASSIGNMENT  STEP UP JOINT AND JANTA CLINIC', NULL, 'New', NULL, NULL, 0, 0, NULL, NULL, '2026-01-14 18:52:00', '2026-01-14 18:52:00', 0, '8178408980');

-- --------------------------------------------------------

--
-- Table structure for table `infra_ticket_images`
--

CREATE TABLE `infra_ticket_images` (
  `image_id` int NOT NULL,
  `ticket_id` int NOT NULL,
  `image_path` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `infra_ticket_images`
--

INSERT INTO `infra_ticket_images` (`image_id`, `ticket_id`, `image_path`, `created_at`) VALUES
(1, 143, 'uploads/infra/20251223113858_ee8cc2_Screenshot_2025-01-04_143130.png', '2025-12-23 11:38:59'),
(2, 143, 'uploads/infra/20251223113858_28586f_Screenshot_2025-01-04_143217.png', '2025-12-23 11:38:59'),
(3, 143, 'uploads/infra/20251223113858_c372d7_Screenshot_2025-01-04_143640.png', '2025-12-23 11:38:59'),
(4, 154, 'uploads/infra/20251226112827_c615a6_COLLECTION_ROOM.jpeg', '2025-12-26 11:28:27'),
(5, 156, 'uploads/infra/20251226162031_7f2f76_WhatsApp_Image_2025-12-26_at_4.20.00_PM.jpeg', '2025-12-26 16:20:32'),
(6, 158, 'uploads/infra/20251227115530_5243ad_WhatsApp_Image_2025-12-27_at_11.53.19_AM.jpeg', '2025-12-27 11:55:31'),
(7, 172, 'uploads/infra/20251230175749_e2af59_REPORT__NO_WORKING.pdf', '2025-12-30 17:57:49'),
(8, 177, 'uploads/infra/20251231120356_740a28_FAILED_REPORT.PNG', '2025-12-31 12:03:56'),
(9, 182, 'uploads/infra/20260102143334_43bddb_PHONE_PE_02-01-2026.JPG', '2026-01-02 14:33:34'),
(10, 190, 'uploads/infra/20260105083506_d921b6_WhatsApp_Image_2026-01-05_at_8.31.51_AM.jpeg', '2026-01-05 08:35:06'),
(11, 191, 'uploads/infra/20260105120558_accafd_REPORT.PNG', '2026-01-05 12:05:58'),
(12, 193, 'uploads/infra/20260105133324_79137c_REPORT.PNG', '2026-01-05 13:33:25'),
(13, 196, 'uploads/infra/20260105154858_3254c3_WhatsApp_Image_2026-01-05_at_15.44.46.jpeg', '2026-01-05 15:48:58'),
(14, 201, 'uploads/infra/20260108150250_f8bcca_SCARLET_CLINIC.JPG', '2026-01-08 15:02:51'),
(15, 203, 'uploads/infra/20260108172921_180cf3_WhatsApp_Image_2026-01-08_at_17.24.52.jpeg', '2026-01-08 17:29:21'),
(16, 205, 'uploads/infra/20260109093559_346025_TICKET_2.JPG', '2026-01-09 09:36:00'),
(17, 208, 'uploads/infra/20260110102758_264dd9_CAP.PNG', '2026-01-10 10:27:59'),
(18, 217, 'uploads/infra/20260111152229_7e3d93_TRITON.JPG', '2026-01-11 15:22:29'),
(19, 221, 'uploads/infra/20260113132855_9a8336_WhatsApp_Image_2026-01-13_at_1.24.48_PM.jpeg', '2026-01-13 13:28:56'),
(20, 221, 'uploads/infra/20260113132855_cea589_WhatsApp_Image_2026-01-13_at_1.24.48_PM_(1).jpeg', '2026-01-13 13:28:56');

-- --------------------------------------------------------

--
-- Table structure for table `infra_updates`
--

CREATE TABLE `infra_updates` (
  `update_id` int NOT NULL,
  `ticket_id` int NOT NULL,
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `created_by` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `infra_updates`
--

INSERT INTO `infra_updates` (`update_id`, `ticket_id`, `note`, `created_by`, `created_at`) VALUES
(1, 2, 'Ticket picked by SAHIL BISHT. Commitment set to 30-11-2025 16:00', 'SAHIL BISHT', '2025-11-29 15:30:01'),
(2, 2, 'Ticket picked by SAHIL BISHT. Commitment set to 01-12-2025 16:00', 'SAHIL BISHT', '2025-11-29 15:30:32'),
(3, 6, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 29-11-2025 17:00', 'RAHNUMA KHATOON', '2025-11-29 16:45:31'),
(4, 1, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 01-12-2025 14:00', 'RAHNUMA KHATOON', '2025-11-29 16:52:20'),
(5, 8, 'Ticket picked by Ritesh Kumar. Commitment set to 30-11-2025 13:30', 'Ritesh Kumar', '2025-11-30 12:52:01'),
(6, 5, 'Ticket picked by Ritesh Kumar. Commitment set to 30-11-2025 13:15', 'Ritesh Kumar', '2025-11-30 13:09:33'),
(7, 10, 'Ticket picked by Ritesh Kumar. Commitment set to 01-12-2025 20:00', 'Ritesh Kumar', '2025-11-30 20:00:16'),
(8, 10, 'no fault sir', 'Ritesh Kumar', '2025-12-01 11:55:11'),
(9, 12, 'Ticket picked by Ritesh Kumar. Commitment set to 07-12-2025 18:00', 'Ritesh Kumar', '2025-12-01 12:00:26'),
(10, 11, 'Ticket picked by SAHIL BISHT. Commitment set to 01-12-2025 12:45', 'SAHIL BISHT', '2025-12-01 12:28:49'),
(11, 12, 'Ticket picked by Ritesh Kumar. Commitment set to 01-12-2025 14:00', 'Ritesh Kumar', '2025-12-01 12:57:21'),
(12, 16, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 01-12-2025 14:30', 'RAHNUMA KHATOON', '2025-12-01 13:29:11'),
(13, 14, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 01-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-01 13:29:43'),
(14, 13, 'PDF installation is done.', 'RAHNUMA KHATOON', '2025-12-01 13:30:29'),
(15, 18, 'Ticket picked by Ritesh Kumar. Commitment set to 01-12-2025 16:00', 'Ritesh Kumar', '2025-12-01 15:35:45'),
(16, 22, 'Ticket picked by Rohit Bisht. Commitment set to 02-12-2025 12:15', 'Rohit Bisht', '2025-12-02 12:05:32'),
(17, 21, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 02-12-2025 12:15', 'RAHNUMA KHATOON', '2025-12-02 12:09:19'),
(18, 20, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 02-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-02 12:10:00'),
(19, 19, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 02-12-2025 13:00', 'RAHNUMA KHATOON', '2025-12-02 12:10:18'),
(20, 17, 'multiple system is not connected . only four or five connected', 'Ritesh Kumar', '2025-12-02 12:29:47'),
(21, 17, 'Ticket picked by Ritesh Kumar. Commitment set to 02-12-2025 12:45', 'Ritesh Kumar', '2025-12-02 12:30:06'),
(22, 15, 'multiple system is not connected , only four or five connected', 'Ritesh Kumar', '2025-12-02 12:30:39'),
(23, 15, 'Ticket picked by Ritesh Kumar. Commitment set to 02-12-2025 12:45', 'Ritesh Kumar', '2025-12-02 12:30:47'),
(24, 12, 'Ticket picked by Ritesh Kumar. Commitment set to 07-12-2025 18:00', 'Ritesh Kumar', '2025-12-02 12:31:49'),
(25, 24, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-02 13:10:22'),
(26, 25, 'Ticket picked by SAHIL BISHT. Commitment set to 02-12-2025 14:15', 'SAHIL BISHT', '2025-12-02 14:11:19'),
(27, 25, 'done.', 'SAHIL BISHT', '2025-12-02 14:11:41'),
(28, 30, 'Ticket picked by Ritesh Kumar. Commitment set to 02-12-2025 19:00', 'Ritesh Kumar', '2025-12-02 18:50:23'),
(29, 31, 'Ticket picked by Rohit Bisht. Commitment set to 02-12-2025 20:00', 'Rohit Bisht', '2025-12-02 14:20:11'),
(30, 29, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-03 06:43:55'),
(31, 28, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 03-12-2025 15:30', 'RAHNUMA KHATOON', '2025-12-03 06:44:46'),
(32, 32, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 03-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-03 06:48:01'),
(33, 23, 'Ticket picked by Rohit Bisht. Commitment set to 03-12-2025 12:45', 'Rohit Bisht', '2025-12-03 07:05:23'),
(34, 38, 'Ticket picked by Ritesh Kumar. Commitment set to 03-12-2025 13:00', 'Ritesh Kumar', '2025-12-03 07:23:08'),
(35, 39, 'Ticket picked by Ritesh Kumar. Commitment set to 03-12-2025 14:30', 'Ritesh Kumar', '2025-12-03 08:54:08'),
(36, 43, 'Ticket picked by Ritesh Kumar. Commitment set to 03-12-2025 19:30', 'Ritesh Kumar', '2025-12-03 13:56:33'),
(37, 45, 'Ticket picked by Ritesh Kumar. Commitment set to 04-12-2025 12:00', 'Ritesh Kumar', '2025-12-04 06:01:04'),
(38, 47, 'Ticket picked by Ritesh Kumar. Commitment set to 04-12-2025 11:45', 'Ritesh Kumar', '2025-12-04 06:14:17'),
(39, 46, 'Ticket picked by Ritesh Kumar. Commitment set to 07-12-2025 18:00', 'Ritesh Kumar', '2025-12-04 06:24:50'),
(40, 46, 'ABHI LIGHT KA STOCK NAHI HAI KAL TAKK ARRANGE HO JAYEGA.. JAISE HE AAJAYEGA WAISE HE CHANGE KAR DENGE...', 'Ritesh Kumar', '2025-12-04 06:25:35'),
(41, 27, 'Ticket picked by Ritesh Kumar. Commitment set to 04-12-2025 12:00', 'Ritesh Kumar', '2025-12-04 06:27:29'),
(42, 33, 'Ticket picked by Ritesh Kumar. Commitment set to 07-12-2025 16:00', 'Ritesh Kumar', '2025-12-04 06:28:58'),
(43, 49, 'Ticket picked by Ritesh Kumar. Commitment set to 05-12-2025 12:15', 'Ritesh Kumar', '2025-12-05 06:43:03'),
(44, 53, 'Ticket picked by Ritesh Kumar. Commitment set to 05-12-2025 15:00', 'Ritesh Kumar', '2025-12-05 07:05:46'),
(45, 54, 'Its looking check it 12:49 PM	HOPE CLINIC	A-22, HAUZ KHAS	Sample Pick Up (Rider) / Please send someone for sample collection thank you	Online', 'RAHNUMA KHATOON', '2025-12-05 07:21:39'),
(46, 53, 'AUTOCLAVE KA SWITCH KHARAB HO GYA HAI NEW LGWANA PAREGA', 'Ritesh Kumar', '2025-12-05 07:42:06'),
(47, 53, 'AUTOCLAVE KA SWITCH KHARAB HO GYA HAI NEW LGWANA PAREGA', 'Ritesh Kumar', '2025-12-05 07:42:26'),
(48, 54, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-05 07:45:55'),
(49, 52, 'Its not gone auto sending by my staff name Jyoti sharma , Aman, Jaspal', 'RAHNUMA KHATOON', '2025-12-05 07:50:22'),
(50, 48, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-05 07:50:49'),
(51, 55, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-05 07:52:27'),
(52, 56, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-05 07:52:43'),
(53, 26, 'Ticket picked by Ritesh Kumar. Commitment set to 05-12-2025 13:15', 'Ritesh Kumar', '2025-12-05 07:53:00'),
(54, 57, 'Ticket picked by SAHIL BISHT. Commitment set to 05-12-2025 18:00', 'SAHIL BISHT', '2025-12-05 10:05:53'),
(55, 44, 'opened', 'ANKITA', '2025-12-05 10:22:49'),
(56, 44, 'Ticket picked by Ritesh Kumar. Commitment set to 05-12-2025 15:45', 'Ritesh Kumar', '2025-12-05 10:24:23'),
(57, 62, 'Ticket picked by Ritesh Kumar. Commitment set to 06-12-2025 10:45', 'Ritesh Kumar', '2025-12-06 05:10:22'),
(58, 61, 'Ticket picked by Ritesh Kumar. Commitment set to 06-12-2025 10:45', 'Ritesh Kumar', '2025-12-06 05:10:45'),
(59, 57, 'Ticket picked by SAHIL BISHT. Commitment set to 06-12-2025 18:00', 'SAHIL BISHT', '2025-12-06 06:57:45'),
(60, 63, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 06-12-2025 13:15', 'RAHNUMA KHATOON', '2025-12-06 07:43:03'),
(61, 65, 'Ticket picked by Ritesh Kumar. Commitment set to 06-12-2025 17:00', 'Ritesh Kumar', '2025-12-06 11:29:38'),
(62, 60, 'Ticket picked by SAHIL BISHT. Commitment set to 06-12-2025 18:00', 'SAHIL BISHT', '2025-12-06 12:21:01'),
(63, 70, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 08-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-08 09:19:04'),
(64, 66, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 08-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-08 09:19:28'),
(65, 41, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 08-12-2025 21:00', 'Dr Vipul Bhasin', '2025-12-08 15:19:56'),
(66, 58, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 08-12-2025 21:00', 'Dr Vipul Bhasin', '2025-12-08 15:26:08'),
(67, 72, 'Ticket picked by Rohit Bisht. Commitment set to 09-12-2025 12:00', 'Rohit Bisht', '2025-12-09 06:26:21'),
(68, 75, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 09-12-2025 12:45', 'RAHNUMA KHATOON', '2025-12-09 07:10:19'),
(69, 51, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 09-12-2025 14:00', 'RAHNUMA KHATOON', '2025-12-09 07:20:03'),
(70, 50, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 09-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-09 07:22:14'),
(71, 40, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 09-12-2025 14:00', 'RAHNUMA KHATOON', '2025-12-09 07:22:57'),
(72, 76, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 09-12-2025 13:45', 'Dr Vipul Bhasin', '2025-12-09 08:08:08'),
(73, 73, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 09-12-2025 14:15', 'RAHNUMA KHATOON', '2025-12-09 08:25:52'),
(74, 59, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 09-12-2025 14:00', 'RAHNUMA KHATOON', '2025-12-09 08:28:45'),
(75, 78, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 10-12-2025 13:00', 'RAHNUMA KHATOON', '2025-12-10 06:32:23'),
(76, 79, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 10-12-2025 12:30', 'RAHNUMA KHATOON', '2025-12-10 06:39:56'),
(77, 83, 'Ticket picked by Rohit Bisht. Commitment set to 10-12-2025 20:00', 'Rohit Bisht', '2025-12-10 14:17:49'),
(78, 83, 'Ticket picked by Rohit Bisht. Commitment set to 10-12-2025 19:45', 'Rohit Bisht', '2025-12-10 14:18:20'),
(79, 83, 'Ticket picked by Rohit Bisht. Commitment set to 10-12-2025 19:00', 'Rohit Bisht', '2025-12-10 14:19:47'),
(80, 84, 'Ticket picked by Rohit Bisht. Commitment set to 10-12-2025 20:00', 'Rohit Bisht', '2025-12-10 14:23:29'),
(81, 85, 'Ticket picked by SAHIL BISHT. Commitment set to 11-12-2025 12:45', 'SAHIL BISHT', '2025-12-11 12:44:39'),
(82, 71, 'Ticket picked by SAHIL BISHT. Commitment set to 11-12-2025 20:00', 'SAHIL BISHT', '2025-12-11 15:12:04'),
(83, 91, 'Ticket picked by SAHIL BISHT. Commitment set to 12-12-2025 12:00', 'SAHIL BISHT', '2025-12-12 11:32:27'),
(84, 90, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 12-12-2025 12:00', 'RAHNUMA KHATOON', '2025-12-12 11:57:29'),
(85, 92, 'Ticket picked by SAHIL BISHT. Commitment set to 12-12-2025 13:30', 'SAHIL BISHT', '2025-12-12 12:47:23'),
(86, 94, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 13-12-2025 15:15', 'RAHNUMA KHATOON', '2025-12-12 15:05:13'),
(87, 93, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 13-12-2025 13:00', 'RAHNUMA KHATOON', '2025-12-12 15:05:32'),
(88, 97, 'Ticket picked by SAHIL BISHT. Commitment set to 12-12-2025 19:45', 'SAHIL BISHT', '2025-12-12 19:35:36'),
(89, 96, 'Ticket picked by SAHIL BISHT. Commitment set to 12-12-2025 19:45', 'SAHIL BISHT', '2025-12-12 19:36:19'),
(90, 95, 'Ticket picked by SAHIL BISHT. Commitment set to 12-12-2025 19:45', 'SAHIL BISHT', '2025-12-12 19:36:30'),
(91, 89, 'Ticket picked by SALEEM JAVED. Commitment set to 13-12-2025 13:15', 'SALEEM JAVED', '2025-12-13 13:12:15'),
(92, 68, 'Ticket picked by SALEEM JAVED. Commitment set to 13-12-2025 13:15', 'SALEEM JAVED', '2025-12-13 13:13:13'),
(93, 89, 'NEED A FIELD EXECUTIVE INFORMED TO AMAN SHUKLA', 'SALEEM JAVED', '2025-12-13 13:18:03'),
(94, 89, 'Ticket picked by SALEEM JAVED. Commitment set to 14-12-2025 15:45', 'SALEEM JAVED', '2025-12-13 15:41:27'),
(95, 98, 'Ticket picked by Rohit Bisht. Commitment set to 13-12-2025 19:00', 'Rohit Bisht', '2025-12-13 18:53:29'),
(96, 74, 'Ticket picked by SALEEM JAVED. Commitment set to 13-12-2025 23:45', 'SALEEM JAVED', '2025-12-13 20:55:37'),
(97, 99, 'Ticket picked by Rohit Bisht. Commitment set to 15-12-2025 18:00', 'Rohit Bisht', '2025-12-15 12:11:47'),
(98, 99, 'Ticket picked by Rohit Bisht. Commitment set to 15-12-2025 20:45', 'Rohit Bisht', '2025-12-15 19:17:05'),
(99, 102, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 12:45', 'RAHNUMA KHATOON', '2025-12-16 12:20:35'),
(100, 102, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 12:45', 'RAHNUMA KHATOON', '2025-12-16 12:20:39'),
(101, 101, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 12:45', 'RAHNUMA KHATOON', '2025-12-16 12:37:57'),
(102, 101, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 12:45', 'RAHNUMA KHATOON', '2025-12-16 12:38:02'),
(103, 103, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-16 12:47:31'),
(104, 103, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-16 12:47:33'),
(105, 103, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-16 12:47:37'),
(106, 103, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-16 12:47:39'),
(107, 104, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 16-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-16 12:48:21'),
(108, 100, 'Ticket picked by SALEEM JAVED. Commitment set to 18-12-2025 16:30', 'SALEEM JAVED', '2025-12-16 16:16:03'),
(109, 100, 'informed to RAM ELECTRICIAN he will come tomorrow', 'SALEEM JAVED', '2025-12-16 18:34:33'),
(110, 108, 'Ticket picked by Ritesh Kumar. Commitment set to 17-12-2025 17:30', 'Ritesh Kumar', '2025-12-17 17:23:15'),
(111, 107, 'Ticket picked by SAHIL BISHT. Commitment set to 18-12-2025 12:30', 'SAHIL BISHT', '2025-12-18 12:22:19'),
(112, 107, 'Ticket picked by SAHIL BISHT. Commitment set to 20-12-2025 12:30', 'SAHIL BISHT', '2025-12-18 12:23:16'),
(113, 80, 'Ticket picked by SAHIL BISHT. Commitment set to 18-12-2025 12:30', 'SAHIL BISHT', '2025-12-18 12:23:35'),
(114, 110, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 18-12-2025 13:00', 'RAHNUMA KHATOON', '2025-12-18 12:28:47'),
(115, 111, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 18-12-2025 13:00', 'RAHNUMA KHATOON', '2025-12-18 12:29:06'),
(116, 109, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 18-12-2025 14:00', 'RAHNUMA KHATOON', '2025-12-18 12:29:19'),
(117, 106, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 18-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-18 12:29:44'),
(118, 105, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 18-12-2025 13:00', 'RAHNUMA KHATOON', '2025-12-18 12:30:19'),
(119, 113, 'Ticket picked by Ritesh Kumar. Commitment set to 19-12-2025 17:00', 'Ritesh Kumar', '2025-12-18 13:25:18'),
(120, 115, 'Ticket picked by SAHIL BISHT. Commitment set to 18-12-2025 19:00', 'SAHIL BISHT', '2025-12-18 18:15:42'),
(121, 116, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 19-12-2025 12:00', 'RAHNUMA KHATOON', '2025-12-19 11:50:21'),
(122, 120, 'Ticket picked by Ritesh Kumar. Commitment set to 19-12-2025 12:45', 'Ritesh Kumar', '2025-12-19 11:57:17'),
(123, 114, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 19-12-2025 13:00', 'RAHNUMA KHATOON', '2025-12-19 11:59:25'),
(124, 122, 'done', 'ANKITA', '2025-12-19 12:41:35'),
(125, 88, 'done', 'ANKITA', '2025-12-19 12:42:00'),
(126, 122, 'Ticket picked by ANKITA. Commitment set to 19-12-2025 13:00', 'ANKITA', '2025-12-19 12:47:07'),
(127, 124, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 19-12-2025 13:30', 'RAHNUMA KHATOON', '2025-12-19 13:20:31'),
(128, 123, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 19-12-2025 14:00', 'RAHNUMA KHATOON', '2025-12-19 13:20:44'),
(129, 121, 'Ticket picked by SAHIL BISHT. Commitment set to 19-12-2025 14:30', 'SAHIL BISHT', '2025-12-19 14:22:45'),
(130, 119, 'Ticket picked by Ritesh Kumar. Commitment set to 20-12-2025 17:00', 'Ritesh Kumar', '2025-12-19 16:24:19'),
(131, 113, 'Ticket picked by Ritesh Kumar. Commitment set to 20-12-2025 16:30', 'Ritesh Kumar', '2025-12-19 16:27:52'),
(132, 125, 'Ticket picked by SAHIL BISHT. Commitment set to 20-12-2025 18:00', 'SAHIL BISHT', '2025-12-19 16:32:55'),
(133, 125, 'done. now maximun file limit is 6', 'SAHIL BISHT', '2025-12-19 18:39:23'),
(134, 129, 'Ticket picked by Ritesh Kumar. Commitment set to 20-12-2025 18:45', 'Ritesh Kumar', '2025-12-19 18:52:58'),
(135, 128, 'Ticket picked by Ritesh Kumar. Commitment set to 21-12-2025 18:45', 'Ritesh Kumar', '2025-12-19 18:53:12'),
(136, 127, 'Ticket picked by Ritesh Kumar. Commitment set to 19-12-2025 19:00', 'Ritesh Kumar', '2025-12-19 18:53:37'),
(137, 126, 'Ticket picked by Ritesh Kumar. Commitment set to 19-12-2025 20:00', 'Ritesh Kumar', '2025-12-19 18:54:11'),
(138, 118, 'Ticket picked by Ritesh Kumar. Commitment set to 21-12-2025 18:45', 'Ritesh Kumar', '2025-12-19 18:54:26'),
(139, 130, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:00', 'ANKITA', '2025-12-20 12:48:09'),
(140, 130, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:00', 'ANKITA', '2025-12-20 12:48:11'),
(141, 130, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:00', 'ANKITA', '2025-12-20 12:48:14'),
(142, 130, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:00', 'ANKITA', '2025-12-20 12:48:29'),
(143, 130, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:00', 'ANKITA', '2025-12-20 12:48:32'),
(144, 130, 'DONE CREATED BY ME', 'ANKITA', '2025-12-20 12:49:52'),
(145, 88, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:00', 'ANKITA', '2025-12-20 12:53:13'),
(146, 131, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:00', 'ANKITA', '2025-12-20 12:59:17'),
(147, 132, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:15', 'ANKITA', '2025-12-20 13:06:19'),
(148, 133, 'Ticket picked by ANKITA. Commitment set to 20-12-2025 13:30', 'ANKITA', '2025-12-20 13:23:53'),
(149, 134, 'Ticket picked by SAHIL BISHT. Commitment set to 20-12-2025 20:15', 'SAHIL BISHT', '2025-12-20 20:11:11'),
(150, 137, 'Ticket picked by SAHIL BISHT. Commitment set to 22-12-2025 12:45', 'SAHIL BISHT', '2025-12-22 12:41:24'),
(151, 140, 'Ticket picked by SAHIL BISHT. Commitment set to 22-12-2025 12:45', 'SAHIL BISHT', '2025-12-22 12:43:00'),
(152, 112, 'Ticket picked by Rohit Bisht. Commitment set to 25-12-2025 20:00', 'Rohit Bisht', '2025-12-22 12:54:51'),
(153, 112, 'arprai.bhasinpathlabs.com:3002', 'Rohit Bisht', '2025-12-22 14:19:01'),
(154, 141, 'PANEL COMPANY NAME SHOUL BE - DR ABHISHEK SHUKLA', 'Shahana Parveen', '2025-12-22 20:17:23'),
(155, 142, 'Ticket picked by Rohit Bisht. Commitment set to 23-12-2025 20:00', 'Rohit Bisht', '2025-12-23 11:27:35'),
(156, 143, 'Ticket picked by Rohit Bisht. Commitment set to 23-12-2025 11:45', 'Rohit Bisht', '2025-12-23 11:39:21'),
(157, 145, 'Ticket picked by Ritesh Kumar. Commitment set to 23-12-2025 13:30', 'Ritesh Kumar', '2025-12-23 13:19:22'),
(158, 144, 'Ticket picked by Ritesh Kumar. Commitment set to 23-12-2025 13:30', 'Ritesh Kumar', '2025-12-23 13:19:58'),
(159, 138, 'Ticket picked by Ritesh Kumar. Commitment set to 24-12-2025 19:45', 'Ritesh Kumar', '2025-12-23 13:25:05'),
(160, 135, 'Ticket picked by Ritesh Kumar. Commitment set to 24-12-2025 19:45', 'Ritesh Kumar', '2025-12-23 13:26:28'),
(161, 148, 'Ticket picked by SAHIL BISHT. Commitment set to 24-12-2025 19:00', 'SAHIL BISHT', '2025-12-24 11:35:35'),
(162, 146, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 24-12-2025 16:00', 'RAHNUMA KHATOON', '2025-12-24 12:08:56'),
(163, 147, 'I update only bill in header', 'RAHNUMA KHATOON', '2025-12-24 12:12:33'),
(164, 147, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 24-12-2025 12:30', 'RAHNUMA KHATOON', '2025-12-24 12:15:26'),
(165, 139, 'Ticket picked by Ritesh Kumar. Commitment set to 24-12-2025 12:45', 'Ritesh Kumar', '2025-12-24 12:33:11'),
(166, 149, 'Ticket picked by Rohit Bisht. Commitment set to 24-12-2025 13:45', 'Rohit Bisht', '2025-12-24 13:34:05'),
(167, 149, 'Ticket picked by Rohit Bisht. Commitment set to 25-12-2025 14:00', 'Rohit Bisht', '2025-12-24 13:46:16'),
(168, 149, 'data is not available in employee master data sheet so please employee registraion form first', 'Rohit Bisht', '2025-12-24 13:47:20'),
(169, 141, 'Ticket picked by ANKITA. Commitment set to 24-12-2025 15:15', 'ANKITA', '2025-12-24 15:00:02'),
(170, 150, 'Ticket picked by Ritesh Kumar. Commitment set to 25-12-2025 19:30', 'Ritesh Kumar', '2025-12-24 19:02:31'),
(171, 136, 'Ticket picked by Ritesh Kumar. Commitment set to 26-12-2025 19:30', 'Ritesh Kumar', '2025-12-24 19:04:31'),
(172, 153, 'Our IVD PCR system is down. The SSD has been corrupted, preventing the system from booting.', 'SAHIL BISHT', '2025-12-25 17:16:32'),
(173, 153, 'Ticket picked by SAHIL BISHT. Commitment set to 27-12-2025 17:30', 'SAHIL BISHT', '2025-12-25 17:12:12'),
(174, 154, 'Ticket picked by Ritesh Kumar. Commitment set to 26-12-2025 14:30', 'Ritesh Kumar', '2025-12-26 14:18:42'),
(175, 153, 'The SSD of the IVD PCR system got damaged/corrupted', 'SAHIL BISHT', '2025-12-26 15:30:24'),
(176, 156, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 27-12-2025 16:00', 'RAHNUMA KHATOON', '2025-12-27 12:03:07'),
(177, 155, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 29-12-2025 16:00', 'RAHNUMA KHATOON', '2025-12-27 12:03:36'),
(178, 152, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 29-12-2025 15:00', 'RAHNUMA KHATOON', '2025-12-27 12:04:04'),
(179, 158, 'Ticket picked by Ritesh Kumar. Commitment set to 30-12-2025 18:00', 'Ritesh Kumar', '2025-12-27 15:34:49'),
(180, 157, 'Ticket picked by Ritesh Kumar. Commitment set to 27-12-2025 15:45', 'Ritesh Kumar', '2025-12-27 15:34:57'),
(181, 159, 'Ticket picked by Ritesh Kumar. Commitment set to 29-12-2025 19:00', 'Ritesh Kumar', '2025-12-27 16:46:12'),
(182, 160, 'DONE', 'ANKITA', '2025-12-27 16:51:11'),
(183, 160, 'Ticket picked by ANKITA. Commitment set to 27-12-2025 17:00', 'ANKITA', '2025-12-27 16:51:18'),
(184, 161, 'Ticket picked by Ritesh Kumar. Commitment set to 27-12-2025 18:45', 'Ritesh Kumar', '2025-12-27 18:41:59'),
(185, 164, 'Ticket picked by SAHIL BISHT. Commitment set to 29-12-2025 17:00', 'SAHIL BISHT', '2025-12-29 12:00:55'),
(186, 164, 'Ticket picked by SAHIL BISHT. Commitment set to 29-12-2025 19:30', 'SAHIL BISHT', '2025-12-29 12:01:08'),
(187, 163, 'Ticket picked by SAHIL BISHT. Commitment set to 29-12-2025 20:00', 'SAHIL BISHT', '2025-12-29 12:01:32'),
(188, 162, 'Ticket picked by SAHIL BISHT. Commitment set to 29-12-2025 12:15', 'SAHIL BISHT', '2025-12-29 12:01:42'),
(189, 153, 'Ticket picked by SAHIL BISHT. Commitment set to 05-01-2026 12:15', 'SAHIL BISHT', '2025-12-29 12:02:12'),
(190, 165, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 29-12-2025 14:30', 'RAHNUMA KHATOON', '2025-12-29 12:36:09'),
(191, 166, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 31-12-2025 16:00', 'RAHNUMA KHATOON', '2025-12-29 13:04:13'),
(192, 167, 'Ticket picked by SAHIL BISHT. Commitment set to 01-01-2026 18:15', 'SAHIL BISHT', '2025-12-29 18:06:33'),
(193, 164, 'Ticket picked by SAHIL BISHT. Commitment set to 29-12-2025 18:15', 'SAHIL BISHT', '2025-12-29 18:06:57'),
(194, 163, 'Ticket picked by SAHIL BISHT. Commitment set to 29-12-2025 18:15', 'SAHIL BISHT', '2025-12-29 18:07:12'),
(195, 169, 'Ticket picked by SAHIL BISHT. Commitment set to 30-12-2025 18:00', 'SAHIL BISHT', '2025-12-30 13:10:27'),
(196, 168, 'Ticket picked by ANKITA. Commitment set to 30-12-2025 15:00', 'ANKITA', '2025-12-30 14:47:53'),
(197, 169, 'Ticket picked by SAHIL BISHT. Commitment set to 31-12-2025 18:15', 'SAHIL BISHT', '2025-12-30 18:07:08'),
(198, 173, 'Ticket picked by SAHIL BISHT. Commitment set to 31-12-2025 16:00', 'SAHIL BISHT', '2025-12-31 12:14:10'),
(199, 177, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 31-12-2025 14:15', 'Dr Vipul Bhasin', '2025-12-31 13:38:19'),
(200, 172, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 31-12-2025 13:45', 'Dr Vipul Bhasin', '2025-12-31 13:40:59'),
(201, 170, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 31-12-2025 15:00', 'Dr Vipul Bhasin', '2025-12-31 14:16:21'),
(202, 176, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 31-12-2025 16:00', 'RAHNUMA KHATOON', '2025-12-31 14:56:23'),
(203, 117, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 01-01-2026 15:00', 'RAHNUMA KHATOON', '2025-12-31 14:58:03'),
(204, 169, 'Ticket picked by SAHIL BISHT. Commitment set to 01-01-2026 17:30', 'SAHIL BISHT', '2025-12-31 17:16:15'),
(205, 178, 'Ticket picked by SAHIL BISHT. Commitment set to 01-01-2026 17:15', 'SAHIL BISHT', '2026-01-01 17:06:09'),
(206, 151, 'Ticket picked by Ritesh Kumar. Commitment set to 01-01-2026 18:45', 'Ritesh Kumar', '2026-01-01 18:42:21'),
(207, 175, 'Ticket picked by Ritesh Kumar. Commitment set to 03-01-2026 19:45', 'Ritesh Kumar', '2026-01-01 19:00:29'),
(208, 174, 'Ticket picked by Ritesh Kumar. Commitment set to 03-01-2026 19:15', 'Ritesh Kumar', '2026-01-01 19:01:03'),
(209, 180, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 03-01-2026 14:00', 'RAHNUMA KHATOON', '2026-01-02 13:50:52'),
(210, 181, 'INOFRMED TO ROHIT IN IT', 'SALEEM JAVED', '2026-01-02 14:35:22'),
(211, 181, 'Ticket picked by Rohit Bisht. Commitment set to 02-01-2026 14:45', 'Rohit Bisht', '2026-01-02 14:38:35'),
(212, 182, 'Ticket picked by Rohit Bisht. Commitment set to 02-01-2026 15:00', 'Rohit Bisht', '2026-01-02 14:38:48'),
(213, 183, 'Ticket picked by Rohit Bisht. Commitment set to 02-01-2026 17:45', 'Rohit Bisht', '2026-01-02 17:30:37'),
(214, 153, 'We tried to retrieve the data from the SSD, but it couldn’t be recovered — the SSD is corrupted.', 'SAHIL BISHT', '2025-12-28 18:22:49'),
(215, 153, 'Now we have installed a new CPU there so that work continues without interruption.', 'SAHIL BISHT', '2025-12-30 18:31:11'),
(216, 184, 'Ticket picked by Ritesh Kumar. Commitment set to 04-01-2026 14:00', 'Ritesh Kumar', '2026-01-03 12:48:45'),
(217, 179, 'Ticket picked by Ritesh Kumar. Commitment set to 04-01-2026 13:00', 'Ritesh Kumar', '2026-01-03 12:48:53'),
(218, 185, 'informed to rehnuma', 'SALEEM JAVED', '2026-01-03 16:49:33'),
(219, 185, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 03-01-2026 19:30', 'RAHNUMA KHATOON', '2026-01-03 19:15:28'),
(220, 189, 'Ticket picked by ANKITA. Commitment set to 05-01-2026 08:45', 'ANKITA', '2026-01-05 08:32:35'),
(221, 191, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-01-2026 14:30', 'RAHNUMA KHATOON', '2026-01-05 12:08:33'),
(222, 190, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-01-2026 12:45', 'RAHNUMA KHATOON', '2026-01-05 12:38:10'),
(223, 187, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-01-2026 12:45', 'RAHNUMA KHATOON', '2026-01-05 12:40:28'),
(224, 193, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 05-01-2026 15:00', 'RAHNUMA KHATOON', '2026-01-05 13:36:15'),
(225, 192, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 07-01-2026 16:00', 'RAHNUMA KHATOON', '2026-01-05 13:36:39'),
(226, 153, 'Ticket picked by SAHIL BISHT. Commitment set to 07-01-2026 14:15', 'SAHIL BISHT', '2026-01-05 14:04:19'),
(227, 194, 'Ticket picked by Ritesh Kumar. Commitment set to 06-01-2026 16:15', 'Ritesh Kumar', '2026-01-05 15:28:48'),
(228, 196, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 05-01-2026 18:30', 'Dr Vipul Bhasin', '2026-01-05 17:45:04'),
(229, 196, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 05-01-2026 18:30', 'Dr Vipul Bhasin', '2026-01-05 17:45:05'),
(230, 196, 'This upgrade is not possible. If required Ticket Tags can be used!', 'Dr Vipul Bhasin', '2026-01-05 17:45:58'),
(231, 195, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 05-01-2026 18:00', 'Dr Vipul Bhasin', '2026-01-05 17:46:35'),
(232, 195, 'Please use Google Sheets', 'Dr Vipul Bhasin', '2026-01-05 17:46:47'),
(233, 188, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 05-01-2026 18:00', 'Dr Vipul Bhasin', '2026-01-05 17:47:42'),
(234, 197, 'Ticket picked by Ritesh Kumar. Commitment set to 05-01-2026 19:45', 'Ritesh Kumar', '2026-01-05 18:58:39'),
(235, 153, 'I\'ve installed the software and inserted protocol files in the system. But the old data wasn\'t recovered. Now, data from new tests will be saved', 'SAHIL BISHT', '2026-01-06 12:04:30'),
(236, 198, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 06-01-2026 14:45', 'RAHNUMA KHATOON', '2026-01-06 14:35:12'),
(237, 198, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 06-01-2026 14:45', 'RAHNUMA KHATOON', '2026-01-06 14:35:14'),
(238, 199, 'Ticket picked by Ritesh Kumar. Commitment set to 10-01-2026 17:00', 'Ritesh Kumar', '2026-01-08 15:46:45'),
(239, 200, 'Ticket picked by Ritesh Kumar. Commitment set to 10-01-2026 19:30', 'Ritesh Kumar', '2026-01-08 15:47:08'),
(240, 203, 'Ticket picked by ANKITA. Commitment set to 09-01-2026 15:00', 'ANKITA', '2026-01-09 09:40:57'),
(241, 202, 'Ticket picked by ANKITA. Commitment set to 09-01-2026 09:45', 'ANKITA', '2026-01-09 09:41:12'),
(242, 186, 'done', 'ANKITA', '2026-01-09 09:50:17'),
(243, 186, 'Ticket picked by ANKITA. Commitment set to 09-01-2026 10:00', 'ANKITA', '2026-01-09 09:51:31'),
(244, 204, 'Ticket picked by Ritesh Kumar. Commitment set to 09-01-2026 15:30', 'Ritesh Kumar', '2026-01-09 15:28:15'),
(245, 207, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 12-01-2026 16:00', 'RAHNUMA KHATOON', '2026-01-10 12:42:52'),
(246, 207, 'As I check Auto whatsapp working please send patient id', 'RAHNUMA KHATOON', '2026-01-10 12:43:21'),
(247, 208, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 12-01-2026 16:00', 'RAHNUMA KHATOON', '2026-01-10 12:43:57'),
(248, 206, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 12-01-2026 15:00', 'RAHNUMA KHATOON', '2026-01-10 12:44:23'),
(249, 205, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 10-01-2026 16:00', 'Dr Vipul Bhasin', '2026-01-10 14:43:48'),
(250, 205, 'Screenshot is incomplete & the shared photo is already resolved, hence ticket will be closed without any action', 'Dr Vipul Bhasin', '2026-01-10 14:45:18'),
(251, 210, '@Ritesh - Please note that this ticket has been made for workstation number 47.', 'Dr Vipul Bhasin', '2026-01-10 14:46:21'),
(252, 211, 'Ticket picked by ANKITA. Commitment set to 10-01-2026 23:45', 'ANKITA', '2026-01-10 14:48:31'),
(253, 211, 'PANEL COMPANY CREATED', 'ANKITA', '2026-01-10 14:48:52'),
(254, 210, 'Ticket picked by Ritesh Kumar. Commitment set to 10-01-2026 19:45', 'Ritesh Kumar', '2026-01-10 16:48:19'),
(255, 213, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 11-01-2026 02:00', 'Dr Vipul Bhasin', '2026-01-11 00:40:21'),
(256, 212, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 11-01-2026 02:00', 'Dr Vipul Bhasin', '2026-01-11 00:40:27'),
(257, 213, 'Sorry, but this authority is not possible for your user at this time. \r\nIf a patient calls for a report older than 3 months, you can simply inform that you do not have access to old data &\r\nthe a report which is less than 1 YEAR, it will be provided within 24 hours and any report older than 1 year will take 3 working days! \r\nAlso remember for any such report you would need to make CCE Ticket or Infra Ticket respectively!', 'Dr Vipul Bhasin', '2026-01-11 00:45:09'),
(258, 212, 'Sorry, but this authority is not possible for your user at this time. \r\nIf a patient calls for a report older than 3 months, you can simply inform that you do not have access to old data &\r\nthe a report which is less than 1 YEAR, it will be provided within 24 hours and any report older than 1 year will take 3 working days! \r\nAlso remember for any such report you would need to make CCE Ticket or Infra Ticket respectively!', 'Dr Vipul Bhasin', '2026-01-11 00:45:28'),
(259, 201, 'It seems you wanted it for Scarlet Clinic (as you have not mentioned the Panel Company here)!\r\nIf so, the update was already done!', 'Dr Vipul Bhasin', '2026-01-11 00:51:44'),
(260, 201, 'Ticket picked by Dr Vipul Bhasin. Commitment set to 11-01-2026 02:15', 'Dr Vipul Bhasin', '2026-01-11 00:51:56'),
(261, 216, 'Ticket picked by Ritesh Kumar. Commitment set to 11-01-2026 13:00', 'Ritesh Kumar', '2026-01-11 12:47:03'),
(262, 214, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 12-01-2026 16:00', 'RAHNUMA KHATOON', '2026-01-12 15:58:14'),
(263, 217, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 12-01-2026 16:15', 'RAHNUMA KHATOON', '2026-01-12 16:00:41'),
(264, 218, 'Ticket picked by Ritesh Kumar. Commitment set to 12-01-2026 17:15', 'Ritesh Kumar', '2026-01-12 17:05:27'),
(265, 221, 'Ticket picked by Ritesh Kumar. Commitment set to 13-01-2026 15:00', 'Ritesh Kumar', '2026-01-13 14:40:42'),
(266, 222, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 13-01-2026 15:45', 'RAHNUMA KHATOON', '2026-01-13 15:36:30'),
(267, 220, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 13-01-2026 15:45', 'RAHNUMA KHATOON', '2026-01-13 15:36:43'),
(268, 223, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 13-01-2026 17:00', 'RAHNUMA KHATOON', '2026-01-13 15:56:13'),
(269, 228, 'Ticket picked by Ritesh Kumar. Commitment set to 15-01-2026 10:45', 'Ritesh Kumar', '2026-01-14 11:27:26'),
(270, 227, 'Ticket picked by Ritesh Kumar. Commitment set to 15-01-2026 18:30', 'Ritesh Kumar', '2026-01-14 11:27:52'),
(271, 231, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 14-01-2026 18:45', 'RAHNUMA KHATOON', '2026-01-14 18:42:13'),
(272, 226, 'Ticket picked by RAHNUMA KHATOON. Commitment set to 15-01-2026 18:45', 'RAHNUMA KHATOON', '2026-01-14 18:42:37');

-- --------------------------------------------------------

--
-- Table structure for table `nc_escalation_forms`
--

CREATE TABLE `nc_escalation_forms` (
  `id` int NOT NULL,
  `hiccup_id` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `staff_name` varchar(200) COLLATE utf8mb4_general_ci NOT NULL,
  `issue_description` text COLLATE utf8mb4_general_ci,
  `root_cause_flags` text COLLATE utf8mb4_general_ci,
  `root_cause_explanation` text COLLATE utf8mb4_general_ci,
  `corrective_action` text COLLATE utf8mb4_general_ci,
  `corrective_action_by` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `corrective_action_date` date DEFAULT NULL,
  `person_responsible` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `timeline_for_completion` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `followup_review` text COLLATE utf8mb4_general_ci,
  `preventive_actions` text COLLATE utf8mb4_general_ci,
  `preventive_details` text COLLATE utf8mb4_general_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `root_cause_other` text COLLATE utf8mb4_general_ci,
  `preventive_other` text COLLATE utf8mb4_general_ci,
  `assigned_staff_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `nc_escalation_forms`
--

INSERT INTO `nc_escalation_forms` (`id`, `hiccup_id`, `staff_name`, `issue_description`, `root_cause_flags`, `root_cause_explanation`, `corrective_action`, `corrective_action_by`, `corrective_action_date`, `person_responsible`, `timeline_for_completion`, `followup_review`, `preventive_actions`, `preventive_details`, `created_at`, `updated_at`, `root_cause_other`, `preventive_other`, `assigned_staff_id`) VALUES
(1, 'HCP-26-014', 'Rohit Bisht', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[\"performance_monitoring\", \"process_refresher\", \"written_warning\"]', NULL, '2026-01-14 13:51:30', '2026-01-14 14:01:32', NULL, NULL, 2241);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `contact` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `departments` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `role` varchar(50) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'staff_user',
  `status` enum('Active','Inactive') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Active',
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dob` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `designation` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `department_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `password`, `contact`, `departments`, `role`, `status`, `last_updated`, `dob`, `designation`, `department_id`) VALUES
(1, 'MD ARIF SAIFI', 'PBPL00422', '8586873925', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '14/04/2000', 'Admin', NULL),
(2, 'Rohit Kumar Pandey', 'PBPL00112', '9598226263', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/07/1993', 'Admin', NULL),
(3, 'Vivek kumar Tiwari', 'PBPL00174', '7531031254', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/06/1997', 'Admin', NULL),
(4, 'Namrita yadav', 'PBPL00513', '8882358029', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '09/12/2004', 'Customer Care', NULL),
(5, 'Mashroor khan', 'PBPL00529', '8527201519', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/03/1997', 'Customer Care', NULL),
(6, 'Sanjeet Kumar', 'PBPL00197', '7982256085', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '24/12/1987', 'Customer Care', NULL),
(7, 'Ritu Mahalwal', 'PBPL 00312', '9871366002', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '25/03/1985', 'Customer Care', NULL),
(8, 'RAHNUMA KHATOON', 'PBPL00104', '8573929263', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/06/1994', 'Admin', NULL),
(9, 'Manisha', 'PBPL00561', '7042308798', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '04/10/1999', 'Customer Care', NULL),
(10, 'Sushil Kumar', 'PBPL00208', '9717852423', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/02/1991', 'Center Phlebo', NULL),
(11, 'Sumit Sirishwal', 'Pbpl000387', '8448010951', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '29/06/1998', 'Customer Care', NULL),
(12, 'KIRAN MANRAL', 'PBPL00500', '8392819642', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '08/04/1998', 'Center Phlebo', NULL),
(13, 'GIRDHAR SINGH BORA', 'PBPL00590', '9971381045', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/09/1996', 'Technical', NULL),
(14, 'Firoz Saifi', 'PBPL00569', '7827967669', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '22/05/1994', 'Home Collection Phlebo', NULL),
(15, 'Himani Rawat', 'PBPL006027', '9990226100', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '29/09/2005', 'Technical', NULL),
(16, 'SAMI AHMAD KHAN', 'PBPL00409', '7520132030', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '17/09/2003', 'Technical', NULL),
(17, 'Aman Shukla', 'PBPL00382', '8178408980', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/03/2002', 'Field', NULL),
(18, 'Ravi Chaudhary', 'PBPL00204', '9811005760', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '14/10/1990', 'Technical', NULL),
(19, 'Roopa Rani', 'PBPL00353', '9915932746', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '21/08/1994', 'Center Phlebo', NULL),
(20, 'SUMIT SINGH', 'PBPL00502', '9821957370', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '05/01/1997', 'Home Collection Phlebo', NULL),
(21, 'Neeraj kumar', 'PBPL00190', '7503711127', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/2002', 'Field', NULL),
(22, 'Kailash', 'PBBL0000134', '9810375490', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '12/03/1996', 'Field', NULL),
(23, 'Keshav', 'PBBL00415', '9871860499', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '11/05/1998', 'Field', NULL),
(24, 'Aman Ahmed', 'PBPL00411', '7827865007', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '21/07/2001', 'Field', NULL),
(25, 'Jyoti sakya', 'PBPL00524', '9718879504', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/04/1998', 'Center Phlebo', NULL),
(26, 'Khemchand', 'PBPL00175', '9953699384', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '03/09/1989', 'Field', NULL),
(27, 'Gulrez Sultan', 'PBPL00556', '9818247844', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/02/1985', 'Customer Care', NULL),
(28, 'SHIV KUMAR', 'PBPL 00130', '9643658494', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '03/05/1988', 'Field', NULL),
(29, 'Priyanka Raikwar', 'PBPL00207', '8447623749', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '21/10/1985', 'Admin', NULL),
(30, 'Rahul Sharma', 'PBPL006014', '7701967897', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '23/01/1996', 'Field', NULL),
(31, 'Mohit kumar', 'PBPL00341', '9773568276', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/07/2001', 'Field', NULL),
(32, 'ADNAN KHAN', 'PBPL00633', '6396202648', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '26/07/2002', 'Technical', NULL),
(33, 'Megha', 'PBPL 00559', '8810356910', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '27/04/1996', 'Customer Care', NULL),
(34, 'Razmi kamal', 'PBPL00184', '8586996357', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '12/05/1967', 'Field', NULL),
(35, 'Shahana Parveen', 'PBPL00176', '8448546358', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/07/1995', 'Marketing', NULL),
(36, 'Anshu kumari', 'PBPL006020', '8920619900', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '28/05/2003', 'Technical', NULL),
(37, 'Abhimanyu Singh', 'PBPL00106', '9971406089', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '11/02/1993', 'Marketing', NULL),
(38, 'Moinul hasan', 'Pbpl00605', '9310937653', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '02/05/2000', 'Home Collection Phlebo', NULL),
(39, 'DEEPAK SENGAR', 'PBPL00475', '8810428595', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '01/07/1996', 'Field', NULL),
(40, 'Gunjan mehta', 'PBPL-00439', '9810312510', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '12/03/1983', 'Marketing', NULL),
(41, 'Ritesh Kumar', 'PBPL00171', '9695983021', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '06/08/1993', 'Admin', NULL),
(42, 'Kanak lata Pallai', 'PBPL00168', '9910240993', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '24/04/1980', 'Technical', NULL),
(43, 'Arti', 'PBPL00431', '7065467760', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '15/09/1999', 'Center Phlebo', NULL),
(44, 'AKASH', 'PBPL00517', '8755346358', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '25/03/2002', 'Center Phlebo', NULL),
(45, 'Dipanshi', 'PBPL006012', '8527343704', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/01/2003', 'Technical', NULL),
(46, 'SHAHBAZ MOHSIN', 'PBPL00558', '7982379071', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/02/1985', 'Center Phlebo', NULL),
(47, 'Kanchana Manral', 'PBPL00444', '8650299233', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/06/2002', 'Technical', NULL),
(48, 'Manish', 'PBPL006046', '8130861621', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '11/09/1996', 'Field', NULL),
(49, 'Rajeev kumar', 'PBPL00154', '7210004748', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '06/08/2000', 'Field', NULL),
(50, 'Mohd aftab alam', 'PBPL006052', '8468957851', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '20/01/1995', 'Center Phlebo', NULL),
(51, 'Mahendra pal', 'PBPL00390', '9625756762', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/02/1998', 'Home Collection Phlebo', NULL),
(52, 'SAHIL BISHT', 'PBPL006029', '8057054076', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/02/2002', 'Admin', NULL),
(53, 'KARAN JHA', 'PBPL00170', '7678489842', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '08/07/1996', 'Admin', NULL),
(54, 'Zeenat', 'PBPL00541', '8920707932', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/10/2001', 'Center Phlebo', NULL),
(55, 'Rohit Kumar', 'PBL006030', '8808290797', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '20/01/1997', 'House Keeping', NULL),
(56, 'Asha', 'PBPL000317', '9625993539', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/03/2000', 'Center Phlebo', NULL),
(57, 'Ritu Rawat', 'PBPL006023', '8130256945', '2', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '04/10/1995', 'House Keeping', NULL),
(58, 'Sachin', 'PBPL00510', '8441890010', '2', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '04/03/2002', 'House Keeping', NULL),
(59, 'Md Shaquib Alam', 'PBPL00520', '8448558464', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/07/1998', 'Technical', NULL),
(60, 'VIMAL RANJAN PANDEY', 'PBPL00198', '8826140791', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '25/07/1993', 'Technical', NULL),
(61, 'MOHD AARISH', 'PBPL00485', '9315144233', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '22/09/1999', 'Center Phlebo', NULL),
(62, 'Jyoti Marwah', 'PBPL00504', '9821189006', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '27/08/1991', 'Technical', NULL),
(63, 'AMAN CHOTALA', 'pbpl00229', '9773552558', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '28/06/1999', 'Customer Care', NULL),
(64, 'Imran Ansari', 'Pbpl00373', '7277209636', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/01/2001', 'Technical', NULL),
(65, 'MOHD KARAM ALI', 'PBPL00173', '8383036512', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/1988', 'Center Phlebo', NULL),
(66, 'Ravi Kumar Pandey', 'PBPL000463', '9565438695', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/07/2003', 'Technical', NULL),
(67, 'Beena Bisht', 'PBPL00432', '9999123130', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '08/10/1991', 'Technical', NULL),
(68, 'Harshita Basnuwal', 'PBPL00434', '8505916252', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '24/02/2002', 'Technical', NULL),
(69, 'Mohd moin husain', 'PBPL006045', '6392969672', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/07/2005', 'Customer Care', NULL),
(70, 'Binita Devi', 'PBPL00578', '8506854833', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/1987', 'House Keeping', NULL),
(71, 'Mukesh', 'PBPL006017', '7982506422', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/08/1984', 'Home Collection Phlebo', NULL),
(72, 'Samreen Mirza', 'PBPL06018', '8448338630', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '22/02/2002', 'Center Phlebo', NULL),
(73, 'Komal', 'PBPL00507', '8920977782', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/11/1998', 'Center Phlebo', NULL),
(74, 'Azeem Ahmed', 'PBPL00231', '9911994840', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '18/12/1995', 'Home Collection Phlebo', NULL),
(75, 'Ragini', 'PBPL006075', '9205031246', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '03/09/1999', 'Center Phlebo', NULL),
(76, 'SABBO', 'PBPL006007', '9310503665', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/01/2000', 'Center Phlebo', NULL),
(77, 'Jaspal singh rawat', 'PBPL006035', '7838686369', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '19/08/1994', 'Customer Care', NULL),
(78, 'Vishal', 'PBPL00530', '7015352509', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '27/10/1998', 'Center Phlebo', NULL),
(79, 'Sabbir', 'PBPL00531', '7217660742', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '19/09/2002', 'Center Phlebo', NULL),
(80, 'Atish', 'PBPL00535', '9310388376', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '07/04/2003', 'Center Phlebo', NULL),
(81, 'Shashi Bhushan Kumar', 'PBPL00113', '9315844775', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/04/1982', 'Home Collection Phlebo', NULL),
(82, 'Uday Pratap Yadav', 'PBPL006038', '9140006961', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/12/1998', 'Admin', NULL),
(83, 'Abhishek Chauhan', 'PBPL00116', '9717009238', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '29/08/2000', 'Center Phlebo', NULL),
(84, 'SUJATA LILHARE', 'PBPLP00381', '9552928353', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '14/10/2000', 'Center Phlebo', NULL),
(85, 'SALEEM JAVED', 'PBPL00212', '9654441851', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '17/07/1973', 'Customer Care', NULL),
(86, 'Vishvender', 'PBPL00332', '8700965931', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/03/1995', 'Home Collection Phlebo', NULL),
(87, 'Vandana', 'PBPL00413', '8076585534', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '05/07/2003', 'Center Phlebo', NULL),
(88, 'Mohd gayas alam', 'PBPL00318', '9058860807', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '08/07/2001', 'Home Collection Phlebo', NULL),
(89, 'PUSHPENDER', 'PBPLl00423', '9910474470', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/05/1999', 'Home Collection Phlebo', NULL),
(90, 'Aashu kashyap', 'PBPL00584', '6203999124', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '23/05/2000', 'Admin', NULL),
(91, 'A . Sylvia', 'PBPL00441', '8838592205', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '17/02/1998', 'Technical', NULL),
(92, 'Mohammad Waseem', 'PBPL00555', '7065718317', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '04/01/1997', 'Technical', NULL),
(93, 'Rupa', 'PBPL00452', '9582878288', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '03/07/1993', 'Center Phlebo', NULL),
(94, 'Sarika', 'PBPL006011', '9899414239', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '12/04/2004', 'Technical', NULL),
(95, 'ANKITA', 'PBPL00188', '8700004157', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/02/2002', 'Customer Care', NULL),
(96, 'Sujeet kumar', 'PBPL00514', '8375038528', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '04/01/2001', 'Center Phlebo', NULL),
(97, 'Maria Dass', 'PBPL00177', '9654876714', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/06/1977', 'Customer Care', NULL),
(98, 'Neeraj Kumar Mandal', 'PBPL00247', '7011876467', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '17/01/2001', 'Center Phlebo', NULL),
(99, 'Prerna', 'PBPL00505', '8826879686', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '11/10/2001', 'Technical', NULL),
(100, 'Anshuman kumar', 'PBPL00585', '9155817760', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '05/07/1998', 'Technical', NULL),
(101, 'Mehrab alam', 'PBPL00523', '9891952645', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '21/09/1997', 'Home Collection Phlebo', NULL),
(102, 'Ram bharosha', 'PBPL006048', '7827479365', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '02/07/1998', 'Field', NULL),
(103, 'Vandana Maurya', 'PBPL00465', '8299806719', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '20/10/1999', 'Center Phlebo', NULL),
(104, 'DHANBIR SINGH RAWAT', 'PBPL00139', '7291848485', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '12/11/1972', 'Marketing', NULL),
(105, 'Shagun', 'PBPL00451', '9318474986', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '11/11/2000', 'Technical', NULL),
(106, 'Akshay Kumar Ram', 'PBPL00562', '9958547534', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '31/03/1998', 'House Keeping', NULL),
(107, 'Yash Sharma', 'PBPL00488', '8800953795', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '04/03/2005', 'House Keeping', NULL),
(108, 'Reena Khandelwal', 'PBPL006034', '8585993878', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '02/07/1986', 'Admin', NULL),
(109, 'Suresh Kundra', 'PBPL006056', '9667798385', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '06/02/1981', 'Customer Care', NULL),
(110, 'Natthu Ram', 'PBPL006042', '9821942388', '2', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '01/01/1980', 'House Keeping', NULL),
(111, 'Saurabh Singh Negi', 'PBPL006063', '7078152416', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '26/09/2003', 'Center Phlebo', NULL),
(112, 'Payal Joshi', 'PBPL006061', '8077832960', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '05/03/2002', 'Technical', NULL),
(113, 'Manwar Singh negi', 'PBPL006057', '9540071850', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '26/08/2002', 'Technical', NULL),
(114, 'Maahi Tiwari', 'PBPL006053', '7678169861', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '22/12/2004', 'Center Phlebo', NULL),
(115, 'Rokhsar Bano', 'PBPL006065', '9315170745', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/02/2003', 'Center Phlebo', NULL),
(116, 'Anuj kumar choudhary', 'PBPL006069', '9625882897', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '03/04/2005', 'Customer Care', NULL),
(117, 'Anisha', 'PBPL006077', '9310058512', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '03/01/2005', 'Center Phlebo', NULL),
(118, 'Riya Agrahari', 'PBPL006081', '8924848255', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '17/07/2002', 'Center Phlebo', NULL),
(119, 'Chitrisha Tiwari', 'PBPL006071', '9311013305', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '24/09/2002', 'Technical', NULL),
(120, 'Md Kalim', 'PBPL006085', '7550425998', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '04/01/1998', 'Home Collection Phlebo', NULL),
(121, 'Surendra pal mahur', 'Pbploo6091', '9810666534', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/05/1978', 'Home Collection Phlebo', NULL),
(122, 'Mahavir Singh Rawat', 'PBPl006086', '9871723521', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '18/09/1974', 'Marketing', NULL),
(123, 'HARENDRA KUMAR', 'PBPL006087', '9958213380', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '22/06/1988', 'Home Collection Phlebo', NULL),
(124, 'Dr Vishu Bhasin', 'Pbpl', '9810637037', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '24/03/1985', 'Admin', NULL),
(125, 'Dr Vipul Bhasin', 'PBPL', '9810030372', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '21/03/1991', 'Admin', NULL),
(126, 'Dr Nitika Aggarwal', 'PBPL', '9311513399', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '08/07/1978', 'Technical', NULL),
(127, 'Dr.Shashikant Singh', 'PBPL', '9540748692', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '28/05/1989', 'Technical', NULL),
(128, 'Prakash Kumar', 'PBPL006070', '9811081575', '2', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '22/09/1977', 'House Keeping', NULL),
(129, 'Sunny', 'PBPL006062', '9811302806', '2', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '24/10/1998', 'House Keeping', NULL),
(130, 'Rakesh Kumar', 'PBPL006068', '9987579418', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '12/08/1990', 'Admin', NULL),
(131, 'Rahul Kumar', 'PBPL006093', '9798895779', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '08/02/2002', 'Technical', NULL),
(132, 'Md Adnan', 'Pbpl006102', '9205956716', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '27/11/2001', 'Home Collection Phlebo', NULL),
(133, 'Harshit', 'PBPL006103', '9310305734', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '26/11/2002', 'Technical', NULL),
(134, 'Bushra khan', 'PBPL006098', '7678617229', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '19/08/2001', 'Technical', NULL),
(135, 'Arvind', 'PBPL006092', '9311270502', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/1998', 'House Keeping', NULL),
(136, 'Satyam kumar', 'PBPL006088', '8595422758', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '28/09/2000', 'Field', NULL),
(137, 'Akash yadav', 'Pbpl006109', '9899847571', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '08/07/2000', 'Customer Care', NULL),
(138, 'Aditya Upadhyay', 'PBPL006110', '6394138497', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '07/04/2004', 'Technical', NULL),
(139, 'Shalini rawat', 'PBPL006107', '9650692437', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/2002', 'Customer Care', NULL),
(140, 'Simran', 'PBPL006108', '8368069817', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/01/2007', 'Admin', NULL),
(141, 'Harsh', 'PBPL006105', '9643447688', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '25/08/2002', 'Field', NULL),
(142, 'Vishakha', 'PBPL006115', '9818924188', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '14/02/2005', 'Center Phlebo', NULL),
(143, 'Saurav kumar', 'PBPL006116', '7428679875', '1,6,5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '01/01/2004', 'Technical', NULL),
(144, 'Mona', 'PBPL006104', '9871963829', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/1986', 'Housekeeping', NULL),
(145, 'Aleyamma Babu', 'PBPL006119', '9891568559', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '22/05/1973', 'Center Phlebo', NULL),
(146, 'Mansi Shukla', 'PBPL006118', '8595713150', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '25/10/2002', 'Technical', NULL),
(147, 'jyoti', 'PBPL006120', '9870554746', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '17/09/2003', 'Customer Care', NULL),
(148, 'Salman khan', 'PBPL006121', '9625052126', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '16/06/1999', 'Customer Care', NULL),
(149, 'Abhishek Raikwar', 'PBPL006122', '8882649327', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '16/07/2004', 'Technical', NULL),
(150, 'Naim Ahmed', 'PBPL006124', '7065310620', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '24/07/2006', 'Field', NULL),
(151, 'shama', 'PBPL006125', '9758109554', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/09/2004', 'Technical', NULL),
(152, 'dhirender singh', 'PBPL006127', '9899004178', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '03/11/1977', 'Customer Care', NULL),
(153, 'Aman', 'PBPL006131', '8448872490', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '25/02/2001', 'Technical', NULL),
(154, 'Faizan', 'PBPL096132', '7310874325', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/2006', 'Center Phlebo', NULL),
(155, 'Mohd Arif', 'PBPL006134', '7409996631', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '04/02/2000', 'Home Collection Phlebo', NULL),
(156, 'Pratiksha', 'PBPL006133', '9717180537', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '07/12/1998', 'Center Phlebo', NULL),
(157, 'AMRIT', 'PBPL006126', '8448234277', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/1987', 'Field', NULL),
(158, 'PRINCE KUMAR', 'PBPL006137', '7018048684', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '16/06/2000', 'Technical', NULL),
(159, 'FAJIL JAMALI', 'PBPL006139', '9837185025', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '17/07/1997', 'Home Collection Phlebo', NULL),
(160, 'Asha', 'PBPL006138', '9625982051', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/08/1999', 'House Keeping', NULL),
(161, 'Khubaib Khan', 'PBPL006140', '9540212849', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '08/05/1999', 'Field', NULL),
(162, 'Prashant Tiwari', 'PBPL006143', '9696983009', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '06/07/2002', 'Home Collection Phlebo', NULL),
(163, 'MD IRPHAN ALAM', 'PBPL006145', '7256934838', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '11/08/2002', 'Home Collection Phlebo', NULL),
(164, 'Karan diwakar', 'PBPL006147', '9899326035', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '18/06/2003', 'Admin', NULL),
(165, 'Suhail Ahmad', 'PBPL006141', '9625719649', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '13/08/2002', 'Field', NULL),
(166, 'Dharmendra Kumar', 'PBPL00135', '9990703607', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/05/1988', 'Home Collection Phlebo', NULL),
(167, 'Piyush Kant Pandey', 'PBPL006149', '9621991792', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '15/07/2025', 'Admin', NULL),
(168, 'Nurain Alam', 'PBPL006150', '8802011784', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '04/12/1994', 'Home Collection Phlebo', NULL),
(169, 'Imran', 'PBPL006151', '9953157867', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '04/12/1994', 'Home Collection Phlebo', NULL),
(170, 'Farzan Husain', 'PBPL006152', '8882392867', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '23/11/2000', 'Home Collection Phlebo', NULL),
(171, 'Srishti Bhadri', 'PBPL006154', '8287561883', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '10/01/2005', 'Customer Care', NULL),
(172, 'SANKET KUMAR', 'PBPL006060', '7870484426', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/04/2004', 'Technical', NULL),
(173, 'Abhay Pratap Singh', 'PBPL006155', '8077609259', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '02/08/1999', 'Home Collection Phlebo', NULL),
(174, 'Tausif Khan', 'PBPL006156', '9128271925', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '04/05/2003', 'Technical', NULL),
(175, 'Shubh Bhatia', 'PBPL006157', '8178444947', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '03/10/2006', 'Customer Care', NULL),
(176, 'Pankaj Kumar', 'PBPL006158', '9310013690', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '08/03/1982', 'Field', NULL),
(177, 'Nancy Dahiya', 'PBPL006159', '8950213781', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '15/07/2000', 'Admin', NULL),
(508, 'Vansh', 'PBPL006160', '9821226071', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '25/07/2003', 'Field', NULL),
(509, 'Rahul Kumar', 'PBPL006161', '8368402477', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/02/2003', 'Admin', NULL),
(510, 'Naveen Sagar', 'PBPL006162', '9716330697', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '16/04/1998', 'Customer Care', NULL),
(511, 'Sheetal Kumari', 'PBPL006165', '8595877546', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '14/10/2004', 'Technical', NULL),
(512, 'Hanzala Khan', 'PBPL006166', '7302234975', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/04/1999', 'Center Phlebo', NULL),
(513, 'Shivam Rathore', 'PBPL006169', '8882385278', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '12/04/2004', 'Admin', NULL),
(514, 'DISHIKA', 'PBPL006170', '8595614476', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/01/2003', 'Center Phlebo', NULL),
(515, 'Kanchan kumari', 'PBPL006171', '9336950360', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/09/1999', 'Technical', NULL),
(516, 'Avid Khan', 'PBPL006167', '9555231281', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '20/07/1987', 'Field', NULL),
(517, 'Pankaj Kumar', 'PBPL006173', '7042228141', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '14/05/1981', 'Field', NULL),
(518, 'Vikas', 'PBPL006175', '8800183241', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '30/07/1993', 'House Keeping', NULL),
(519, 'Suhail', 'PBPL006172', '9599356068', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '02/04/2001', 'House Keeping', NULL),
(520, 'Dilshad Ali', 'PBPL006176', '8595020105', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '08/06/1993', 'Field', NULL),
(521, 'Divyanshi Kumari', 'PBPL006177', '8929962005', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '27/06/1998', 'Center Phlebo', NULL),
(522, 'SONA', 'PBPL006178', '8076741165', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '14/05/2005', 'Customer Care', NULL),
(523, 'Dhiraj Kumar', 'PBPL006168', '7011372648', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/2002', 'House Keeping', NULL),
(524, 'Shalini Kumari', 'PBPL006179', '9354592130', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '20/06/2005', 'Customer Care', NULL),
(1035, 'Saddam Hussain', 'PBPL006180', '7217716998', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '12/12/1995', 'Home Collection Phlebo', NULL),
(1891, 'Harish sharma', 'PBPL006181', '9991372012', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '16/03/2000', 'Technical', NULL),
(2062, 'Tushar Kumar', 'PBPL006183', '7042384668', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/01/2002', 'House Keeping', NULL),
(2234, 'Rani', 'PBPL006185', '9873439864', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '07/03/2005', 'Technical', NULL),
(2235, 'Shreya', 'PBPL006186', '9958439588', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '13/01/2002', 'Technical', NULL),
(2236, 'Komal kashyap', 'PBPL006188', '9717111565', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '07/08/1996', 'Customer Care', NULL),
(2237, 'Kusum', 'PBPL006187', '8882026294', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '20/09/2003', 'Center Phlebo', NULL),
(2238, 'Prathana', 'PBPL006189', '9310240406', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/2006', 'Center Phlebo', NULL),
(2239, 'Sonia', 'PBPL006190', '7290010403', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '02/02/2002', 'Center Phlebo', NULL),
(2240, 'Shruti keshri', 'PBPL006191', '7557783359', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/08/2001', 'Technical', NULL),
(2241, 'Rohit Bisht', 'PBPL006192', '8126382045', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '10/04/2003', 'Admin', NULL),
(2242, 'Alok kumar singh', 'Pbpl006193', '7253017744', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '30/06/2001', 'Home Collection Phlebo', NULL),
(2243, 'Deepak Tiwari', 'PBPL006194', '7082320507', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '16/03/1998', 'Home Collection Phlebo', NULL),
(2244, 'Gaurav Kumar', 'PBPL006184', '7321992699', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '13/02/2006', 'House Keeping', NULL),
(2245, 'Jai shree gupta', 'PBPL006196', '8756419603', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '04/04/2004', 'Admin', NULL),
(2246, 'ATUL BABU PAL', 'PBPL006197', '9953394818', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '03/11/2005', 'Center Phlebo', NULL),
(2247, 'Deep sahani', 'PBPL006198', '9060366914', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '23/05/2005', 'Center Phlebo', NULL),
(2248, 'Rishita', 'PBPL006199', '7011721571', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '15/07/2005', 'Admin', NULL),
(2249, 'Shivam Dwivedi', 'PBPL006200', '9354352988', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '22/09/2002', 'Home Collection Phlebo', NULL),
(2250, 'Prerna Sharma', 'PBPL006202', '9910773271', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '25/09/1984', 'Customer Care', NULL),
(2251, 'Shyam Kumar', 'PBPL006203', '7482816592', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/2005', 'Admin', NULL),
(2252, 'Divya bisht', 'PBPL006204', '9258180594', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '27/05/2006', 'Technical', NULL),
(2253, 'Komal', 'PBPL006201', '8860886621', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '02/10/1990', 'Customer Care', NULL),
(2254, 'Sandeep', 'PBPL006205', '9560932913', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '18/11/1992', 'Field', NULL),
(2255, 'Deepak kumar', 'PBPL006206', '7210236493', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '12/02/2002', 'Home Collection Phlebo', NULL),
(2256, 'Narendra Pal', 'PBPL006207', '8077095025', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '13/01/1993', 'Home Collection Phlebo', NULL),
(2257, 'SONU MAHTO', 'PBPL006208', '8178396134', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '13/07/2000', 'Customer Care', NULL),
(2258, 'Rohan kumar giri', 'PBPL006209', '8292636187', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '04/01/2004', 'Home Collection Phlebo', NULL),
(2259, 'Kiran Pachori', 'PBPL006211', '9625615521', '5', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '04/06/2000', 'Customer Care', NULL),
(2260, 'Sartaj Khan', 'PBPL006195', '9142276775', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/1995', 'Field', NULL),
(2261, 'Monika Rajput', 'PBPL006209', '8742945845', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '27/07/1998', 'Admin', NULL),
(2262, 'Shadab Ali', 'PBPL006210', '7088882143', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '06/07/2000', 'Home Collection Phlebo', NULL),
(2263, 'Harish Kumar', 'PBPL006211', '7011175296', '5,6', 'staff_user', 'Inactive', '2026-01-13 13:30:17', '08/07/1997', 'Home Collection Phlebo', NULL),
(2264, 'Mohd Zaid', 'PBPL006214', '6395460266', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '27/10/2003', 'Home Collection Phlebo', NULL),
(2265, 'Pritam Yadav', 'PBPL006215', '9670046193', '2', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/07/2006', 'House Keeping', NULL),
(2266, 'Khushiya khan', 'PBPL006216', '8104091923', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/10/1994', 'Customer Care', NULL),
(2267, 'Himanshu kumar', 'PBPL006217', '8076685407', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '05/01/2002', 'Field', NULL),
(2268, 'Kaushik burman', 'PBPL006218', '9773877202', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/01/1993', 'Home Collection Phlebo', NULL),
(2269, 'Akash paswan', 'PBPL006219', '8882676701', '5,6', 'staff_user', 'Active', '2026-01-13 13:30:17', '20/11/2000', 'Home Collection Phlebo', NULL),
(2270, 'Deepak ojha', 'PBPL006220', '9310671290', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '14/11/2003', 'Admin', NULL),
(2271, 'Kritika Sharma', 'PBPL006223', '9650538486', '1,6,5', 'staff_user', 'Active', '2026-01-13 13:30:17', '24/10/1999', 'Technical', NULL),
(2272, 'Nishu Kumar', 'PBPL006222', '7820074697', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '09/07/2005', 'Admin', NULL),
(2273, 'Vikram', 'PBPL006224', '9871177543', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '01/12/2000', 'Customer Care', NULL),
(2274, 'Amit Kumar', 'PBPL006225', '9871816112', '5', 'staff_user', 'Active', '2026-01-13 13:30:17', '24/07/1988', 'Field', NULL);

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
  ADD KEY `ix_infra_tickets_ticket_id` (`ticket_id`);

--
-- Indexes for table `infra_ticket_images`
--
ALTER TABLE `infra_ticket_images`
  ADD PRIMARY KEY (`image_id`),
  ADD KEY `ix_infra_ticket_images_image_id` (`image_id`),
  ADD KEY `ix_infra_ticket_images_ticket_id` (`ticket_id`);

--
-- Indexes for table `infra_updates`
--
ALTER TABLE `infra_updates`
  ADD PRIMARY KEY (`update_id`),
  ADD KEY `ix_infra_updates_update_id` (`update_id`),
  ADD KEY `ix_infra_updates_ticket_id` (`ticket_id`);

--
-- Indexes for table `nc_escalation_forms`
--
ALTER TABLE `nc_escalation_forms`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `hiccup_id` (`hiccup_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `department_master`
--
ALTER TABLE `department_master`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `hiccup_audit_log`
--
ALTER TABLE `hiccup_audit_log`
  MODIFY `log_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT for table `infra_tickets`
--
ALTER TABLE `infra_tickets`
  MODIFY `ticket_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=233;

--
-- AUTO_INCREMENT for table `infra_ticket_images`
--
ALTER TABLE `infra_ticket_images`
  MODIFY `image_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `infra_updates`
--
ALTER TABLE `infra_updates`
  MODIFY `update_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=273;

--
-- AUTO_INCREMENT for table `nc_escalation_forms`
--
ALTER TABLE `nc_escalation_forms`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2275;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `hiccups`
--
ALTER TABLE `hiccups`
  ADD CONSTRAINT `fk_hiccups_escalated_by` FOREIGN KEY (`escalated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_hiccups_raised_against_dept` FOREIGN KEY (`raised_against_department`) REFERENCES `department_master` (`id`),
  ADD CONSTRAINT `fk_hiccups_raised_by` FOREIGN KEY (`raised_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_hiccups_raised_by_dept` FOREIGN KEY (`raised_by_department`) REFERENCES `department_master` (`id`),
  ADD CONSTRAINT `fk_hiccups_response_by` FOREIGN KEY (`response_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `hiccup_audit_log`
--
ALTER TABLE `hiccup_audit_log`
  ADD CONSTRAINT `fk_audit_hiccup` FOREIGN KEY (`hiccup_id`) REFERENCES `hiccups` (`hiccup_id`),
  ADD CONSTRAINT `fk_audit_performer` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `nc_escalation_forms`
--
ALTER TABLE `nc_escalation_forms`
  ADD CONSTRAINT `nc_escalation_forms_ibfk_1` FOREIGN KEY (`hiccup_id`) REFERENCES `hiccups` (`hiccup_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
