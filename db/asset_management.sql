-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 29, 2026 at 11:58 AM
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
-- Database: `asset_management`
--

CREATE DATABASE IF NOT EXISTS `asset_management` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `asset_management`;

-- --------------------------------------------------------

--
-- Table structure for table `approval_requests`
--

CREATE TABLE `approval_requests` (
  `id` bigint(20) NOT NULL,
  `approval_number` varchar(40) NOT NULL,
  `action_type` varchar(50) NOT NULL,
  `asset_id` bigint(20) DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  `details` text DEFAULT NULL,
  `requested_by` varchar(80) DEFAULT NULL,
  `decided_by` varchar(80) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `assets`
--

CREATE TABLE `assets` (
  `id` bigint(20) NOT NULL,
  `asset_code` varchar(30) NOT NULL,
  `public_token` varchar(96) NOT NULL,
  `asset_name` varchar(200) NOT NULL,
  `category_id` bigint(20) NOT NULL,
  `asset_type_id` bigint(20) NOT NULL,
  `make_id` bigint(20) DEFAULT NULL,
  `model_text` varchar(200) DEFAULT NULL,
  `serial_number` varchar(150) DEFAULT NULL,
  `criticality` varchar(2) NOT NULL,
  `current_site_id` bigint(20) NOT NULL,
  `current_floor_id` bigint(20) DEFAULT NULL,
  `current_department_id` bigint(20) DEFAULT NULL,
  `current_workstation_id` bigint(20) DEFAULT NULL,
  `staff_incharge_employee_id` bigint(20) NOT NULL,
  `issued_to_employee_id` bigint(20) DEFAULT NULL,
  `primary_service_contact_id` bigint(20) DEFAULT NULL,
  `holding_class` varchar(40) DEFAULT NULL,
  `operational_status` varchar(40) NOT NULL,
  `lifecycle_state` varchar(40) NOT NULL,
  `purchase_date` date DEFAULT NULL,
  `purchase_value` decimal(14,2) DEFAULT NULL,
  `invoice_reference` varchar(150) DEFAULT NULL,
  `warranty_start_date` date DEFAULT NULL,
  `warranty_end_date` date DEFAULT NULL,
  `warranty_document_path` varchar(500) DEFAULT NULL,
  `useful_life_months` int(11) DEFAULT NULL,
  `pm_required` tinyint(1) NOT NULL,
  `pm_period_months` int(11) DEFAULT NULL,
  `calibration_mode` varchar(30) NOT NULL,
  `calibration_period_months` int(11) DEFAULT NULL,
  `primary_photo_path` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_alerts`
--

CREATE TABLE `asset_alerts` (
  `id` bigint(20) NOT NULL,
  `asset_id` bigint(20) DEFAULT NULL,
  `alert_type` varchar(60) NOT NULL,
  `message` text NOT NULL,
  `due_on` date DEFAULT NULL,
  `status` varchar(20) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_categories`
--

CREATE TABLE `asset_categories` (
  `id` bigint(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `asset_categories`
--

INSERT INTO `asset_categories` (`id`, `name`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'IT', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(2, 'Lab Equipment', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(3, 'Office Equipment', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(4, 'Furniture', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55');

-- --------------------------------------------------------

--
-- Table structure for table `asset_documents`
--

CREATE TABLE `asset_documents` (
  `id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `document_type` varchar(50) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `title` varchar(200) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_events`
--

CREATE TABLE `asset_events` (
  `id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `event_type` varchar(60) NOT NULL,
  `message` text NOT NULL,
  `occurred_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_incharge_history`
--

CREATE TABLE `asset_incharge_history` (
  `id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `employee_id` bigint(20) NOT NULL,
  `started_at` datetime NOT NULL,
  `ended_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_issue_history`
--

CREATE TABLE `asset_issue_history` (
  `id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `employee_id` bigint(20) NOT NULL,
  `issued_at` datetime NOT NULL,
  `issued_by` varchar(80) DEFAULT NULL,
  `issue_condition` text DEFAULT NULL,
  `details` text DEFAULT NULL,
  `returned_at` datetime DEFAULT NULL,
  `received_by` varchar(80) DEFAULT NULL,
  `return_condition` text DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_location_history`
--

CREATE TABLE `asset_location_history` (
  `id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `site_id` bigint(20) NOT NULL,
  `floor_id` bigint(20) DEFAULT NULL,
  `department_id` bigint(20) DEFAULT NULL,
  `workstation_id` bigint(20) DEFAULT NULL,
  `started_at` datetime NOT NULL,
  `ended_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_makes`
--

CREATE TABLE `asset_makes` (
  `id` bigint(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `asset_makes`
--

INSERT INTO `asset_makes` (`id`, `name`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Roche', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(2, 'Siemens', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(3, 'Mindray', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(4, 'Dell', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(5, 'HP', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(6, 'Samsung', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(7, 'Daikin', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(8, 'ACER', 1, '2026-08-24 07:42:11', '2026-08-24 07:42:11');

-- --------------------------------------------------------

--
-- Table structure for table `asset_service_contacts`
--

CREATE TABLE `asset_service_contacts` (
  `asset_id` bigint(20) NOT NULL,
  `contact_id` bigint(20) NOT NULL,
  `is_primary` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `asset_types`
--

CREATE TABLE `asset_types` (
  `id` bigint(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `category_id` bigint(20) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `asset_types`
--

INSERT INTO `asset_types` (`id`, `name`, `category_id`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Desktop', 1, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(2, 'Monitor', 1, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(3, 'Laptop', 1, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(4, 'Printer', 1, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(5, 'UPS', 1, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(6, 'Chemistry Analyzer', 2, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(7, 'Centrifuge', 2, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(8, 'Microscope', 2, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(9, 'Air Conditioner', 3, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(10, 'Microwave', 3, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(11, 'Chair', 4, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(12, 'Workstation', 4, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(13, 'Cabinet', 4, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(14, 'CPU', 1, 1, '2026-08-24 07:41:45', '2026-08-24 07:41:45'),
(15, 'KEY BOARD', 1, 1, '2026-08-24 07:48:08', '2026-08-24 07:48:08'),
(16, 'MOUSE ', 1, 1, '2026-08-24 07:55:06', '2026-08-24 07:55:06'),
(17, 'Prodisplay', 1, 1, '2026-08-27 06:06:35', '2026-08-27 06:06:35');

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` bigint(20) NOT NULL,
  `actor` varchar(80) DEFAULT NULL,
  `entity_type` varchar(50) NOT NULL,
  `entity_id` varchar(80) NOT NULL,
  `action` varchar(80) NOT NULL,
  `metadata_text` text DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `calibration_records`
--

CREATE TABLE `calibration_records` (
  `id` bigint(20) NOT NULL,
  `schedule_id` bigint(20) NOT NULL,
  `completed_at` datetime NOT NULL,
  `performed_by` varchar(150) NOT NULL,
  `result` varchar(80) NOT NULL,
  `certificate_path` varchar(500) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `calibration_schedules`
--

CREATE TABLE `calibration_schedules` (
  `id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `frequency_days` int(11) NOT NULL,
  `next_due` date NOT NULL,
  `vendor_id` bigint(20) DEFAULT NULL,
  `active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contract_renewals`
--

CREATE TABLE `contract_renewals` (
  `id` bigint(20) NOT NULL,
  `contract_id` bigint(20) NOT NULL,
  `approval_id` bigint(20) NOT NULL,
  `status` varchar(30) NOT NULL,
  `old_start_date` date DEFAULT NULL,
  `old_end_date` date DEFAULT NULL,
  `new_start_date` date DEFAULT NULL,
  `new_end_date` date DEFAULT NULL,
  `old_value` decimal(14,2) DEFAULT NULL,
  `new_value` decimal(14,2) DEFAULT NULL,
  `reference_number` varchar(100) DEFAULT NULL,
  `document_path` varchar(500) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `renewed_by` varchar(80) DEFAULT NULL,
  `renewed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `floor_id` bigint(20) DEFAULT NULL,
  `id` bigint(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`floor_id`, `id`, `name`, `is_active`, `created_at`, `updated_at`) VALUES
(NULL, 1, 'Biochemistry', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(NULL, 2, 'Hematology', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(NULL, 3, 'Microbiology', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(NULL, 4, 'Customer Care', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(NULL, 5, 'IT', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(NULL, 6, 'Administration', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55');

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `id` bigint(20) NOT NULL,
  `employee_code` varchar(50) NOT NULL,
  `name` varchar(150) NOT NULL,
  `department_id` bigint(20) DEFAULT NULL,
  `designation` varchar(100) DEFAULT NULL,
  `mobile` varchar(30) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`id`, `employee_code`, `name`, `department_id`, `designation`, `mobile`, `email`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'DBL001', 'IT Manager', 5, NULL, NULL, NULL, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(2, 'DBL002', 'Rahul Sharma', 4, NULL, NULL, NULL, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(3, 'EXT-91', 'A . Sylvia', NULL, 'Technical', '8838592205', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(4, 'EXT-90', 'Aashu kashyap', NULL, 'Admin', '6203999124', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(5, 'EXT-37', 'Abhimanyu Singh', NULL, 'Marketing', '9971406089', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(6, 'EXT-83', 'Abhishek Chauhan', NULL, 'Center Phlebo', '9717009238', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(7, 'EXT-2392', 'Abhishek Sharma', NULL, 'Marketing', '7011630322', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(8, 'EXT-2383', 'Ajay kumar', NULL, 'Field', '8178870256', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(9, 'EXT-44', 'AKASH', NULL, 'Center Phlebo', '8755346358', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(10, 'EXT-2387', 'Akash Goswami', NULL, 'Center Phlebo', '8447385429', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(11, 'EXT-137', 'Akash yadav', NULL, 'Customer Care', '9899847571', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(12, 'EXT-2289', 'Akshay Kumar', NULL, 'Admin', '8882193438', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(13, 'EXT-106', 'Akshay Kumar Ram', NULL, 'House Keeping', '9958547534', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(14, 'EXT-145', 'Aleyamma Babu', NULL, 'Center Phlebo', '9891568559', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(15, 'EXT-2400', 'Alka Kumari Singh', NULL, 'Center Phlebo', '9366395918', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(16, 'EXT-24', 'Aman Ahmed', NULL, 'Field', '7827865007', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(17, 'EXT-63', 'AMAN CHOTALA', NULL, 'Customer Care', '9773552558', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(18, 'EXT-2306', 'Aman Kumar', NULL, 'Admin', '8920532392', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(19, 'EXT-17', 'Aman Shukla', NULL, 'Field', '8178408980', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(20, 'EXT-2348', 'Amit kumar', NULL, 'Field', '6280273178', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(21, 'EXT-2305', 'Amit Kumar Gupta', NULL, 'Center Phlebo', '7013842910', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(22, 'EXT-95', 'ANKITA', NULL, 'Customer Care', '8700004157', NULL, 1, '2026-08-21 06:42:58', '2026-08-21 06:42:58'),
(23, 'EXT-2241', 'Rohit Bisht', NULL, 'Admin', '8126382045', NULL, 1, '2026-08-21 06:43:07', '2026-08-21 06:43:07'),
(24, 'EXT-55', 'Rohit Kumar', NULL, 'House Keeping', '8808290797', NULL, 1, '2026-08-21 06:43:07', '2026-08-21 06:43:07'),
(25, 'EXT-2', 'Rohit Kumar Pandey', NULL, 'Admin', '9598226263', NULL, 1, '2026-08-21 06:43:07', '2026-08-21 06:43:07'),
(26, 'EXT-2414', 'Rohit Mani', NULL, 'Customer Care', '9310565062', NULL, 1, '2026-08-21 06:43:07', '2026-08-21 06:43:07'),
(27, 'EXT-2371', 'Arvind Kumar raikwar', NULL, 'Field', '9315928491', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(28, 'EXT-2372', 'BHARAT VERMA', NULL, 'Field', '9821418170', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(29, 'EXT-70', 'Binita Devi', NULL, 'House Keeping', '8506854833', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(30, 'EXT-2393', 'Devender Kumar', NULL, 'Marketing', '9773865082', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(31, 'EXT-2252', 'Divya bisht', NULL, 'Technical', '9258180594', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(32, 'EXT-125', 'Dr Vipul Bhasin', NULL, 'Admin', '9810030372', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(33, 'EXT-124', 'Dr Vishu Bhasin', NULL, 'Admin', '9810637037', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(34, 'EXT-2339', 'Dr. Mohan Vashistha', NULL, 'Technical', '9717561139', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(35, 'EXT-2244', 'Gaurav Kumar', NULL, 'House Keeping', '7321992699', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(36, 'EXT-2308', 'Harvinder', NULL, 'Home Collection Phlebo', '7678241332', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(37, 'EXT-2420', 'Kapil verma', NULL, 'Field', '8448335612', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(38, 'EXT-23', 'Keshav', NULL, 'Field', '9871860499', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(39, 'EXT-2334', 'Krishna Yadav', NULL, 'Technical', '9910798049', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(40, 'EXT-122', 'Mahavir Singh Rawat', NULL, 'Marketing', '9871723521', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(41, 'EXT-2283', 'Mayanglambam Joshita Devi', NULL, 'Center Phlebo', '9366205308', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(42, 'EXT-2380', 'Premavati', NULL, 'Center Phlebo', '8368212830', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(43, 'EXT-2265', 'Pritam Yadav', NULL, 'House Keeping', '9670046193', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(44, 'EXT-49', 'Rajeev kumar', NULL, 'Field', '7210004748', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(45, 'EXT-1', 'MD ARIF SAIFI', NULL, 'Admin', '8586873925', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(46, 'EXT-2279', 'Ruchika sanyal', NULL, 'Customer Care', '9953555790', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(47, 'EXT-79', 'Sabbir', NULL, 'Center Phlebo', '7217660742', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(48, 'EXT-1035', 'Saddam Hussain', NULL, 'Home Collection Phlebo', '7217716998', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(49, 'EXT-52', 'SAHIL BISHT', NULL, 'Admin', '8057054076', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(50, 'EXT-2320', 'Sakshi Dwivedi', NULL, 'Technical', '9625412093', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(51, 'EXT-85', 'SALEEM JAVED', NULL, 'Customer Care', '9654441851', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(52, 'EXT-2336', 'SALMAN', NULL, 'Technical', '9643365081', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(53, 'EXT-16', 'SAMI AHMAD KHAN', NULL, 'Technical', '7520132030', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(54, 'EXT-72', 'Samreen Mirza', NULL, 'Center Phlebo', '8448338630', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(55, 'EXT-6', 'Sanjeet Kumar', NULL, 'Customer Care', '7982256085', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(56, 'EXT-2316', 'Sanjeev kumar', NULL, 'Technical', '7060718443', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(57, 'EXT-2381', 'Sanjeev Kumar Chauhan', NULL, 'House Keeping', '9315269694', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(58, 'EXT-2376', 'Sanjeev Kumar dass', NULL, 'Admin', '9599586359', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(59, 'EXT-172', 'SANKET KUMAR', NULL, 'Technical', '7870484426', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(60, 'EXT-2419', 'SAQLAIN RAZA REHMANI', NULL, 'Technical', '9142263665', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(61, 'EXT-2260', 'Sartaj Khan', NULL, 'Field', '9142276775', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(62, 'EXT-136', 'Satyam kumar', NULL, 'Field', '8595422758', NULL, 1, '2026-08-21 06:57:17', '2026-08-21 06:57:17'),
(63, 'EXT-2395', 'ANUJ AGRAAHARI', NULL, 'House Keeping', '8527062561', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(64, 'EXT-56', 'Asha', NULL, 'Center Phlebo', '9625993539', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(65, 'EXT-2284', 'Ashish Bharti', NULL, 'Center Phlebo', '7294933831', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(66, 'EXT-2337', 'Dr. Priyanka Rana', NULL, 'Technical', '8860211191', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(67, 'EXT-1891', 'Harish sharma', NULL, 'Technical', '9991372012', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(68, 'EXT-2412', 'Harsh bhadouriya', NULL, 'Technical', '9473554990', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(69, 'EXT-515', 'Kanchan kumari', NULL, 'Technical', '9336950360', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(70, 'EXT-2276', 'Kirti kumari', NULL, 'Technical', '9310005345', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(71, 'EXT-2271', 'Kritika Sharma', NULL, 'Technical', '9650538486', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(72, 'EXT-114', 'Maahi Tiwari', NULL, 'Center Phlebo', '7678169861', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(73, 'EXT-97', 'Maria Dass', NULL, 'Customer Care', '9654876714', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(74, 'EXT-61', 'MOHD AARISH', NULL, 'Center Phlebo', '9315144233', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(75, 'EXT-29', 'Priyanka Raikwar', NULL, 'Admin', '8447623749', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(76, 'EXT-2402', 'Rishu Sharma', NULL, 'Technical', '9310733107', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(77, 'EXT-41', 'Ritesh Kumar', NULL, 'Admin', '9695983021', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(78, 'EXT-2345', 'Ritika', NULL, 'Center Phlebo', '7678413070', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(79, 'EXT-2301', 'RITIKA', NULL, 'Technical', '9289128660', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(80, 'EXT-7', 'Ritu Mahalwal', NULL, 'Customer Care', '9871366002', NULL, 1, '2026-08-22 07:22:35', '2026-08-22 07:22:35'),
(81, 'EXT-2307', 'PAWAN ARORA', NULL, 'Field', '9899231315', NULL, 1, '2026-08-22 07:22:37', '2026-08-22 07:22:37'),
(82, 'EXT-2421', 'ROHIT KUMAR', NULL, 'House Keeping', '9958594485', NULL, 1, '2026-08-22 07:22:37', '2026-08-22 07:22:37'),
(83, 'EXT-19', 'Roopa Rani', NULL, 'Center Phlebo', '9915932746', NULL, 1, '2026-08-22 07:22:37', '2026-08-22 07:22:37'),
(84, 'EXT-27', 'Gulrez Sultan', NULL, 'Customer Care', '9818247844', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(85, 'EXT-2237', 'Kusum', NULL, 'Center Phlebo', '8882026294', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(86, 'EXT-2367', 'Masum', NULL, 'Field', '9934473588', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(87, 'EXT-84', 'SUJATA LILHARE', NULL, 'Center Phlebo', '9552928353', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(88, 'EXT-96', 'Sujeet kumar', NULL, 'Center Phlebo', '8375038528', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(89, 'EXT-2304', 'Suman', NULL, 'Technical', '8368143697', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(90, 'EXT-20', 'SUMIT SINGH', NULL, 'Home Collection Phlebo', '9821957370', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(91, 'EXT-2413', 'Suraj Kumar', NULL, 'Customer Care', '9582420527', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(92, 'EXT-2409', 'Suraj Thakur', NULL, 'Technical', '9643175702', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(93, 'EXT-2379', 'Surendra kumar', NULL, 'Field', '8377072771', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(94, 'EXT-121', 'Surendra pal mahur', NULL, 'Home Collection Phlebo', '9810666534', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(95, 'EXT-109', 'Suresh Kundra', NULL, 'Customer Care', '9667798385', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(96, 'EXT-2404', 'Surjeet Singh Rawat', NULL, 'Admin', '7701961954', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(97, 'EXT-10', 'Sushil Kumar', NULL, 'Center Phlebo', '9717852423', NULL, 1, '2026-08-24 07:24:51', '2026-08-24 07:24:51'),
(98, 'EXT-2359', 'Ashish Kumar', NULL, 'Technical', '9336224942', NULL, 1, '2026-08-24 07:52:30', '2026-08-24 07:52:30'),
(99, 'EXT-80', 'Atish', NULL, 'Center Phlebo', '9310388376', NULL, 1, '2026-08-24 07:52:30', '2026-08-24 07:52:30'),
(100, 'EXT-2313', 'Ayushi', NULL, 'Technical', '8810413109', NULL, 1, '2026-08-24 07:52:30', '2026-08-24 07:52:30'),
(101, 'EXT-78', 'Vishal', NULL, 'Center Phlebo', '7015352509', NULL, 1, '2026-08-27 06:07:38', '2026-08-27 06:07:38'),
(102, 'EXT-2318', 'Vishal Kumar', NULL, 'Admin', '9971531560', NULL, 1, '2026-08-27 06:07:38', '2026-08-27 06:07:38'),
(103, 'EXT-2408', 'Chandan Jha', NULL, 'Admin', '9958593916', NULL, 1, '2026-08-27 06:08:05', '2026-08-27 06:08:05'),
(104, 'EXT-47', 'Kanchana Manral', NULL, 'Technical', '8650299233', NULL, 1, '2026-08-27 06:08:05', '2026-08-27 06:08:05'),
(105, 'EXT-26', 'Khemchand', NULL, 'Field', '9953699384', NULL, 1, '2026-08-27 06:08:05', '2026-08-27 06:08:05'),
(106, 'EXT-74', 'Azeem Ahmed', NULL, 'Home Collection Phlebo', '9911994840', NULL, 1, '2026-08-27 06:11:35', '2026-08-27 06:11:35'),
(107, 'EXT-2373', 'Balbir Chauhan', NULL, 'Field', '7703928856', NULL, 1, '2026-08-27 06:11:35', '2026-08-27 06:11:35'),
(108, 'EXT-2384', 'DILEEP KUMAR SETHI', NULL, 'Home Collection Phlebo', '8650200563', NULL, 1, '2026-08-27 06:11:35', '2026-08-27 06:11:35'),
(109, 'EXT-45', 'Dipanshi', NULL, 'Technical', '8527343704', NULL, 1, '2026-08-27 06:11:35', '2026-08-27 06:11:35'),
(110, 'EXT-18', 'Ravi Chaudhary', NULL, 'Technical', '9811005760', NULL, 1, '2026-08-27 06:13:34', '2026-08-27 06:13:34'),
(111, 'EXT-66', 'Ravi Kumar Pandey', NULL, 'Technical', '9565438695', NULL, 1, '2026-08-27 06:13:34', '2026-08-27 06:13:34'),
(112, 'EXT-2280', 'Vibhor Naithani', NULL, 'Customer Care', '7834834912', NULL, 1, '2026-08-27 06:13:34', '2026-08-27 06:13:34'),
(113, 'EXT-2398', 'VIJAY SINGH RAWAT', NULL, 'Home Collection Phlebo', '8851485941', NULL, 1, '2026-08-27 06:13:34', '2026-08-27 06:13:34'),
(114, 'EXT-2273', 'Vikram', NULL, 'Customer Care', '9871177543', NULL, 1, '2026-08-27 06:13:34', '2026-08-27 06:13:34'),
(115, 'EXT-60', 'VIMAL RANJAN PANDEY', NULL, 'Technical', '8826140791', NULL, 1, '2026-08-27 06:13:34', '2026-08-27 06:13:34'),
(116, 'EXT-2375', 'Vinay kumar', NULL, 'Field', '9910807645', NULL, 1, '2026-08-27 06:13:34', '2026-08-27 06:13:34'),
(117, 'EXT-86', 'Vishvender', NULL, 'Home Collection Phlebo', '8700965931', NULL, 1, '2026-08-27 06:13:34', '2026-08-27 06:13:34'),
(118, 'EXT-126', 'Dr Nitika Aggarwal', NULL, 'Technical', '9311513399', NULL, 1, '2026-08-27 06:13:41', '2026-08-27 06:13:41'),
(119, 'EXT-2290', 'Dr. Ashish Kumar Mandal', NULL, 'Technical', '9811686403', NULL, 1, '2026-08-27 06:13:41', '2026-08-27 06:13:41'),
(120, 'EXT-13', 'GIRDHAR SINGH BORA', NULL, 'Technical', '9971381045', NULL, 1, '2026-08-27 06:13:41', '2026-08-27 06:13:41'),
(121, 'EXT-133', 'Harshit', NULL, 'Technical', '9310305734', NULL, 1, '2026-08-27 06:13:41', '2026-08-27 06:13:41'),
(122, 'EXT-68', 'Harshita Basnuwal', NULL, 'Technical', '8505916252', NULL, 1, '2026-08-27 06:13:41', '2026-08-27 06:13:41'),
(123, 'EXT-2396', 'Hifza Ahmed', NULL, 'Technical', '6395952306', NULL, 1, '2026-08-27 06:13:41', '2026-08-27 06:13:41'),
(124, 'EXT-62', 'Jyoti Marwah', NULL, 'Technical', '9821189006', NULL, 1, '2026-08-27 06:13:41', '2026-08-27 06:13:41'),
(125, 'EXT-2401', 'Mayank Chauhan', NULL, 'Home Collection Phlebo', '9548659631', NULL, 1, '2026-08-27 06:13:42', '2026-08-27 06:13:42');

-- --------------------------------------------------------

--
-- Table structure for table `external_movements`
--

CREATE TABLE `external_movements` (
  `id` bigint(20) NOT NULL,
  `gate_pass_number` varchar(40) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `movement_type` varchar(30) NOT NULL,
  `destination` varchar(200) NOT NULL,
  `vendor_id` bigint(20) DEFAULT NULL,
  `sent_at` datetime NOT NULL,
  `expected_return` date DEFAULT NULL,
  `returned_at` datetime DEFAULT NULL,
  `status` varchar(30) NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `floors`
--

CREATE TABLE `floors` (
  `id` bigint(20) NOT NULL,
  `name` varchar(100) NOT NULL,
  `site_id` bigint(20) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `floors`
--

INSERT INTO `floors` (`id`, `name`, `site_id`, `created_at`, `updated_at`) VALUES
(1, 'Basement', 1, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(2, 'Ground Floor', 1, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(3, 'First Floor', 1, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(4, 'Second Floor', 1, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(5, 'Third Floor', 1, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(6, 'Basement', 3, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(7, 'Ground Floor', 3, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(8, 'First Floor', 3, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(9, 'Second Floor', 3, '2026-08-27 06:26:36', '2026-08-27 06:26:36'),
(10, 'Third Floor', 3, '2026-08-27 06:26:36', '2026-08-27 06:26:36');

-- --------------------------------------------------------

--
-- Table structure for table `number_sequences`
--

CREATE TABLE `number_sequences` (
  `key` varchar(80) NOT NULL,
  `value` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pm_records`
--

CREATE TABLE `pm_records` (
  `id` bigint(20) NOT NULL,
  `schedule_id` bigint(20) NOT NULL,
  `completed_at` datetime NOT NULL,
  `performed_by` varchar(150) NOT NULL,
  `remarks` text NOT NULL,
  `service_report_path` varchar(500) NOT NULL,
  `cost` decimal(14,2) DEFAULT NULL,
  `calibration_performed` tinyint(1) NOT NULL,
  `calibration_result` varchar(80) DEFAULT NULL,
  `calibration_certificate_path` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pm_schedules`
--

CREATE TABLE `pm_schedules` (
  `id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `frequency_days` int(11) NOT NULL,
  `next_due` date NOT NULL,
  `provider_vendor_id` bigint(20) DEFAULT NULL,
  `reminder_days` int(11) NOT NULL,
  `active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` bigint(20) NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id`, `name`, `description`, `created_at`, `updated_at`) VALUES
(1, 'Administrator', 'Complete system access', '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(2, 'Technician', 'Service, repair, PM and calibration', '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(3, 'Asset Manager', 'Asset lifecycle, contracts and reports', '2026-08-21 12:35:36', '2026-08-21 12:35:36'),
(7, 'Employee', 'Assigned assets and issue reporting', '2026-08-21 12:35:36', '2026-08-21 12:35:36');

-- --------------------------------------------------------

--
-- Table structure for table `service_contacts`
--

CREATE TABLE `service_contacts` (
  `id` bigint(20) NOT NULL,
  `vendor_id` bigint(20) DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `designation` varchar(100) DEFAULT NULL,
  `mobile` varchar(30) DEFAULT NULL,
  `alternate_mobile` varchar(30) DEFAULT NULL,
  `whatsapp` varchar(30) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `service_contacts`
--

INSERT INTO `service_contacts` (`id`, `vendor_id`, `name`, `designation`, `mobile`, `alternate_mobile`, `whatsapp`, `email`, `notes`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'Demo Service Desk', NULL, '1800-000-000', NULL, NULL, NULL, NULL, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(2, NULL, 'test', NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-08-24 09:22:22', '2026-08-24 09:22:22'),
(3, 1, 'check', NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-08-24 09:51:55', '2026-08-24 09:51:55');

-- --------------------------------------------------------

--
-- Table structure for table `service_contracts`
--

CREATE TABLE `service_contracts` (
  `id` bigint(20) NOT NULL,
  `contract_number` varchar(40) NOT NULL,
  `contract_type` varchar(20) NOT NULL,
  `vendor_id` bigint(20) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `value` decimal(14,2) DEFAULT NULL,
  `status` varchar(30) NOT NULL,
  `reference_number` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_contract_assets`
--

CREATE TABLE `service_contract_assets` (
  `contract_id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_tickets`
--

CREATE TABLE `service_tickets` (
  `id` bigint(20) NOT NULL,
  `ticket_number` varchar(40) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  `complaint` text NOT NULL,
  `priority` varchar(20) NOT NULL,
  `status` varchar(30) NOT NULL,
  `resolution_path` varchar(30) DEFAULT NULL,
  `reported_by` varchar(150) DEFAULT NULL,
  `reported_at` datetime NOT NULL,
  `assigned_to` varchar(150) DEFAULT NULL,
  `vendor_id` bigint(20) DEFAULT NULL,
  `vendor_reference` varchar(100) DEFAULT NULL,
  `restored_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `downtime_minutes` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_ticket_events`
--

CREATE TABLE `service_ticket_events` (
  `id` bigint(20) NOT NULL,
  `ticket_id` bigint(20) NOT NULL,
  `event_type` varchar(60) NOT NULL,
  `notes` text DEFAULT NULL,
  `performed_by` varchar(150) DEFAULT NULL,
  `occurred_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `service_ticket_parts`
--

CREATE TABLE `service_ticket_parts` (
  `id` bigint(20) NOT NULL,
  `ticket_id` bigint(20) NOT NULL,
  `description` varchar(250) NOT NULL,
  `quantity` decimal(10,2) NOT NULL,
  `unit_cost` decimal(14,2) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sites`
--

CREATE TABLE `sites` (
  `id` bigint(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sites`
--

INSERT INTO `sites` (`id`, `name`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'GK-1', 1, '2026-08-20 11:53:55', '2026-08-24 14:09:42'),
(2, 'DBGN Gurugram', 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(3, 'Gurgaon', 1, '2026-08-24 14:09:42', '2026-08-24 14:09:42');

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
  `role` varchar(50) NOT NULL DEFAULT 'employee',
  `role_id` bigint(20) NOT NULL DEFAULT 7,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `dob` varchar(10) DEFAULT NULL,
  `designation` varchar(100) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `password`, `contact`, `departments`, `role`, `role_id`, `status`, `last_updated`, `dob`, `designation`, `department_id`) VALUES
(1, 'MD ARIF SAIFI', 'PBPL00422', '8586873925', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/04/2000', 'Admin', NULL),
(2, 'Rohit Kumar Pandey', 'PBPL00112', '9598226263', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/07/1993', 'Admin', NULL),
(3, 'Vivek kumar Tiwari', 'PBPL00174', '7531031254', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/06/1997', 'Admin', NULL),
(4, 'Namrita yadav', 'PBPL00513', '8882358029', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '09/12/2004', 'Customer Care', NULL),
(5, 'Mashroor khan', 'PBPL00529', '8527201519', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/03/1997', 'Customer Care', NULL),
(6, 'Sanjeet Kumar', 'PBPL00197', '7982256085', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '24/12/1987', 'Customer Care', NULL),
(7, 'Ritu Mahalwal', 'PBPL 00312', '9871366002', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '25/03/1985', 'Customer Care', NULL),
(8, 'RAHNUMA KHATOON', 'PBPL00104', '8573929263', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/06/1994', 'Admin', NULL),
(9, 'Manisha', 'PBPL006313', '7042308798', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/10/1999', 'Customer Care', NULL),
(10, 'Sushil Kumar', 'PBPL00208', '9717852423', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/02/1991', 'Center Phlebo', NULL),
(11, 'Sumit Sirishwal', 'Pbpl000387', '8448010951', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '29/06/1998', 'Customer Care', NULL),
(12, 'KIRAN MANRAL', 'PBPL00500', '8392819642', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/04/1998', 'Center Phlebo', NULL),
(13, 'GIRDHAR SINGH BORA', 'PBPL00590', '9971381045', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/09/1996', 'Technical', NULL),
(14, 'Firoz Saifi', 'PBPL00569', '7827967669', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '22/05/1994', 'Home Collection Phlebo', NULL),
(15, 'Himani Rawat', 'PBPL006027', '9990226100', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '29/09/2005', 'Technical', NULL),
(16, 'SAMI AHMAD KHAN', 'PBPL00409', '7520132030', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/09/2003', 'Technical', NULL),
(17, 'Aman Shukla', 'PBPL00382', '8178408980', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/03/2002', 'Field', NULL),
(18, 'Ravi Chaudhary', 'PBPL00204', '9811005760', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/10/1990', 'Technical', NULL),
(19, 'Roopa Rani', 'PBPL00353', '9915932746', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '21/08/1994', 'Center Phlebo', NULL),
(20, 'SUMIT SINGH', 'PBPL006309', '9821957370', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/01/1997', 'Home Collection Phlebo', NULL),
(21, 'Neeraj kumar', 'PBPL00190', '7503711127', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/2002', 'Field', NULL),
(22, 'Kailash', 'PBBL0000134', '9810375490', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '12/03/1996', 'Field', NULL),
(23, 'Keshav', 'PBBL00415', '9871860499', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '11/05/1998', 'Field', NULL),
(24, 'Aman Ahmed', 'PBPL00411', '7827865007', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '21/07/2001', 'Field', NULL),
(25, 'Jyoti sakya', 'PBPL00524', '9718879504', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/04/1998', 'Center Phlebo', NULL),
(26, 'Khemchand', 'PBPL00175', '9953699384', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '03/09/1989', 'Field', NULL),
(27, 'Gulrez Sultan', 'PBPL00556', '9818247844', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/02/1985', 'Customer Care', NULL),
(28, 'SHIV KUMAR', 'PBPL 00130', '9643658494', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '03/05/1988', 'Field', NULL),
(29, 'Priyanka Raikwar', 'PBPL00207', '8447623749', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '21/10/1985', 'Admin', NULL),
(30, 'Rahul Sharma', 'PBPL006014', '7701967897', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '23/01/1996', 'Field', NULL),
(31, 'Mohit kumar', 'PBPL00341', '9773568276', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/07/2001', 'Field', NULL),
(32, 'ADNAN KHAN', 'PBPL00633', '6396202648', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '26/07/2002', 'Technical', NULL),
(33, 'Megha', 'PBPL 00559', '8810356910', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '27/04/1996', 'Customer Care', NULL),
(34, 'Razmi kamal', 'PBPL00184', '8586996357', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '12/05/1967', 'Field', NULL),
(35, 'Shahana Parveen', 'PBPL00176', '8448546358', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/07/1995', 'Marketing', NULL),
(36, 'Anshu kumari', 'PBPL006020', '8920619900', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '28/05/2003', 'Technical', NULL),
(37, 'Abhimanyu Singh', 'PBPL00106', '9971406089', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '11/02/1993', 'Marketing', NULL),
(38, 'Moinul hasan', 'Pbpl00605', '9310937653', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '02/05/2000', 'Home Collection Phlebo', NULL),
(39, 'DEEPAK SENGAR', 'PBPL00475', '8810428595', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/07/1996', 'Field', NULL),
(40, 'Gunjan mehta', 'PBPL00439', '9810312510', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '12/03/1983', 'Marketing', NULL),
(41, 'Ritesh Kumar', 'PBPL00171', '9695983021', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '06/08/1993', 'Admin', NULL),
(42, 'Kanak lata Pallai', 'PBPL00168', '9910240993', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '24/04/1980', 'Technical', NULL),
(43, 'Arti', 'PBPL00431', '7065467760', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/09/1999', 'Center Phlebo', NULL),
(44, 'AKASH', 'PBPL00517', '8755346358', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '25/03/2002', 'Center Phlebo', NULL),
(45, 'Dipanshi', 'PBPL006012', '8527343704', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/01/2003', 'Technical', NULL),
(46, 'SHAHBAZ MOHSIN', 'PBPL00558', '7982379071', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/02/1985', 'Center Phlebo', NULL),
(47, 'Kanchana Manral', 'PBPL00444', '8650299233', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/06/2002', 'Technical', NULL),
(48, 'Manish', 'PBPL006046', '8130861621', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '11/09/1996', 'Field', NULL),
(49, 'Rajeev kumar', 'PBPL00154', '7210004748', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '06/08/2000', 'Field', NULL),
(50, 'Mohd aftab alam', 'PBPL006052', '8468957851', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '20/01/1995', 'Center Phlebo', NULL),
(51, 'Mahendra pal', 'PBPL00390', '9625756762', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/02/1998', 'Home Collection Phlebo', NULL),
(52, 'SAHIL BISHT', 'PBPL006029', '8057054076', '5', 'administrator', 1, 'Active', '2026-08-25 07:31:15', '05/02/2002', 'Admin', NULL),
(53, 'KARAN JHA', 'PBPL00170', '7678489842', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '08/07/1996', 'Admin', NULL),
(54, 'Zeenat', 'PBPL00541', '8920707932', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/10/2001', 'Center Phlebo', NULL),
(55, 'Rohit Kumar', 'PBL006030', '8808290797', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '20/01/1997', 'House Keeping', NULL),
(56, 'Asha', 'PBPL00317', '9625993539', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/03/2000', 'Center Phlebo', NULL),
(57, 'Ritu Rawat', 'PBPL006023', '8130256945', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/10/1995', 'House Keeping', NULL),
(58, 'Sachin', 'PBPL00510', '8441890010', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/03/2002', 'House Keeping', NULL),
(59, 'Md Shaquib Alam', 'PBPL00520', '8448558464', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/07/1998', 'Technical', NULL),
(60, 'VIMAL RANJAN PANDEY', 'PBPL00198', '8826140791', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '25/07/1993', 'Technical', NULL),
(61, 'MOHD AARISH', 'PBPL00485', '9315144233', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '22/09/1999', 'Center Phlebo', NULL),
(62, 'Jyoti Marwah', 'PBPL00504', '9821189006', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '27/08/1991', 'Technical', NULL),
(63, 'AMAN CHOTALA', 'PBPL00229', '9773552558', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '28/06/1999', 'Customer Care', NULL),
(64, 'Imran Ansari', 'Pbpl00373', '7277209636', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/01/2001', 'Technical', NULL),
(65, 'MOHD KARAM ALI', 'PBPL00173', '8383036512', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/1988', 'Center Phlebo', NULL),
(66, 'Ravi Kumar Pandey', 'PBPL00463', '9565438695', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/07/2003', 'Technical', NULL),
(67, 'Beena Bisht', 'PBPL00432', '9999123130', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '08/10/1991', 'Technical', NULL),
(68, 'Harshita Basnuwal', 'PBPL00434', '8505916252', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '24/02/2002', 'Technical', NULL),
(69, 'Mohd moin husain', 'PBPL006045', '6392969672', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/07/2005', 'Customer Care', NULL),
(70, 'Binita Devi', 'PBPL00578', '8506854833', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/1987', 'House Keeping', NULL),
(71, 'Mukesh', 'PBPL006017', '7982506422', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/08/1984', 'Home Collection Phlebo', NULL),
(72, 'Samreen Mirza', 'PBPL006018', '8448338630', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '22/02/2002', 'Center Phlebo', NULL),
(73, 'Komal', 'PBPL00507', '8920977782', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/11/1998', 'Center Phlebo', NULL),
(74, 'Azeem Ahmed', 'PBPL00231', '9911994840', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '18/12/1995', 'Home Collection Phlebo', NULL),
(75, 'Ragini', 'PBPL006075', '9205031246', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '03/09/1999', 'Center Phlebo', NULL),
(76, 'SABBO', 'PBPL006007', '9310503665', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/01/2000', 'Center Phlebo', NULL),
(77, 'Jaspal singh rawat', 'PBPL006035', '7838686369', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '19/08/1994', 'Customer Care', NULL),
(78, 'Vishal', 'PBPL00530', '7015352509', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '27/10/1998', 'Center Phlebo', NULL),
(79, 'Sabbir', 'PBPL00531', '7217660742', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '19/09/2002', 'Center Phlebo', NULL),
(80, 'Atish', 'PBPL00535', '9310388376', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '07/04/2003', 'Center Phlebo', NULL),
(81, 'Shashi Bhushan Kumar', 'PBPL00113', '9315844775', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/04/1982', 'Home Collection Phlebo', NULL),
(82, 'Uday Pratap Yadav', 'PBPL006038', '9140006961', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/12/1998', 'Admin', NULL),
(83, 'Abhishek Chauhan', 'PBPL00116', '9717009238', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '29/08/2000', 'Center Phlebo', NULL),
(84, 'SUJATA LILHARE', 'PBPLP00381', '9552928353', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/10/2000', 'Center Phlebo', NULL),
(85, 'SALEEM JAVED', 'PBPL00212', '9654441851', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/07/1973', 'Customer Care', NULL),
(86, 'Vishvender', 'PBPL00332', '8700965931', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/03/1995', 'Home Collection Phlebo', NULL),
(87, 'Vandana', 'PBPL00413', '8076585534', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/07/2003', 'Center Phlebo', NULL),
(88, 'Mohd gayas alam', 'PBPL00318', '9058860807', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/07/2001', 'Home Collection Phlebo', NULL),
(89, 'PUSHPENDER', 'PBPL00423', '9910474470', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/05/1999', 'Home Collection Phlebo', NULL),
(90, 'Aashu kashyap', 'PBPL00584', '6203999124', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '23/05/2000', 'Admin', NULL),
(91, 'A . Sylvia', 'PBPL00441', '8838592205', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/02/1998', 'Technical', NULL),
(92, 'Mohammad Waseem', 'PBPL00555', '7065718317', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/01/1997', 'Technical', NULL),
(93, 'Rupa', 'PBPL00452', '9582878288', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '03/07/1993', 'Technical', NULL),
(94, 'Sarika', 'PBPL006084', '9899414239', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '12/04/2004', 'Technical', NULL),
(95, 'ANKITA', 'PBPL00188', '8700004157', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/02/2002', 'Customer Care', NULL),
(96, 'Sujeet kumar', 'PBPL00514', '8375038528', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/01/2001', 'Center Phlebo', NULL),
(97, 'Maria Dass', 'PBPL00177', '9654876714', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/06/1977', 'Customer Care', NULL),
(98, 'Neeraj Kumar Mandal', 'PBPL00247', '7011876467', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/01/2001', 'Center Phlebo', NULL),
(99, 'Prerna', 'PBPL00505', '8826879686', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '11/10/2001', 'Technical', NULL),
(100, 'Anshuman kumar', 'PBPL00585', '9155817760', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/07/1998', 'Technical', NULL),
(101, 'Mehrab alam', 'PBPL00523', '9891952645', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '21/09/1997', 'Home Collection Phlebo', NULL),
(102, 'Ram bharosha', 'PBPL006048', '7827479365', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '02/07/1998', 'Field', NULL),
(103, 'Vandana Maurya', 'PBPL00465', '8299806719', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '20/10/1999', 'Center Phlebo', NULL),
(104, 'DHANBIR SINGH RAWAT', 'PBPL00139', '7291848485', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '12/11/1972', 'Marketing', NULL),
(105, 'Shagun', 'PBPL00451', '9318474986', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '11/11/2000', 'Technical', NULL),
(106, 'Akshay Kumar Ram', 'PBPL00562', '9958547534', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '31/03/1998', 'House Keeping', NULL),
(107, 'Yash Sharma', 'PBPL00488', '8800953795', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/03/2005', 'House Keeping', NULL),
(108, 'Reena Khandelwal', 'PBPL006034', '8585993878', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '02/07/1986', 'Admin', NULL),
(109, 'Suresh Kundra', 'PBPL006056', '9667798385', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '06/02/1981', 'Customer Care', NULL),
(110, 'Natthu Ram', 'PBPL006042', '9821942388', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/01/1980', 'House Keeping', NULL),
(111, 'Saurabh Singh Negi', 'PBPL006063', '7078152416', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '26/09/2003', 'Center Phlebo', NULL),
(112, 'Payal Joshi', 'PBPL006061', '8077832960', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/03/2002', 'Technical', NULL),
(113, 'Manwar Singh negi', 'PBPL006057', '9540071850', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '26/08/2002', 'Technical', NULL),
(114, 'Maahi Tiwari', 'PBPL006053', '7678169861', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '22/12/2004', 'Center Phlebo', NULL),
(115, 'Rokhsar Bano', 'PBPL006065', '9315170745', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/02/2003', 'Center Phlebo', NULL),
(116, 'Anuj kumar choudhary', 'PBPL006069', '9625882897', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '03/04/2005', 'Customer Care', NULL),
(117, 'Anisha', 'PBPL006077', '9310058512', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '03/01/2005', 'Center Phlebo', NULL),
(118, 'Riya Agrahari', 'PBPL006081', '8924848255', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/07/2002', 'Center Phlebo', NULL),
(119, 'Chitrisha Tiwari', 'PBPL006071', '9311013305', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '24/09/2002', 'Technical', NULL),
(120, 'Md Kalim', 'PBPL006085', '7550425998', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/01/1998', 'Home Collection Phlebo', NULL),
(121, 'Surendra pal mahur', 'Pbploo6091', '9810666534', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/05/1978', 'Home Collection Phlebo', NULL),
(122, 'Mahavir Singh Rawat', 'PBPl006086', '9871723521', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '18/09/1974', 'Marketing', NULL),
(123, 'Harendra Kumar', 'PBPL006300', '9958213380', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '22/06/1988', 'Home Collection Phlebo', NULL),
(124, 'Dr Vishu Bhasin', 'Pbpl', '9810637037', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '24/03/1985', 'Admin', NULL),
(125, 'Dr Vipul Bhasin', 'PBPL', '9810030372', '5', 'administrator', 1, 'Active', '2026-08-21 14:05:06', '21/03/1991', 'Admin', NULL),
(126, 'Dr Nitika Aggarwal', 'PBPL', '9311513399', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/07/1978', 'Technical', NULL),
(127, 'Dr.Shashikant Singh', 'PBPL', '9540748692', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '28/05/1989', 'Technical', NULL),
(128, 'Prakash Kumar', 'PBPL006070', '9811081575', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '22/09/1977', 'House Keeping', NULL),
(129, 'Sunny', 'PBPL006062', '9811302806', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '24/10/1998', 'House Keeping', NULL),
(130, 'Rakesh Kumar', 'PBPL006068', '9987579418', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '12/08/1990', 'Admin', NULL),
(131, 'Rahul Kumar', 'PBPL006093', '9798895779', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '08/02/2002', 'Technical', NULL),
(132, 'Md Adnan', 'Pbpl006102', '9205956716', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '27/11/2001', 'Home Collection Phlebo', NULL),
(133, 'Harshit', 'PBPL006103', '9310305734', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '26/11/2002', 'Technical', NULL),
(134, 'Bushra khan', 'PBPL006098', '7678617229', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '19/08/2001', 'Technical', NULL),
(135, 'Arvind', 'PBPL006092', '9311270502', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/01/1998', 'House Keeping', NULL),
(136, 'Satyam kumar', 'PBPL006088', '8595422758', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '28/09/2000', 'Field', NULL),
(137, 'Akash yadav', 'PBPL006338', '9899847571', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/07/2000', 'Customer Care', NULL),
(138, 'Aditya Upadhyay', 'PBPL006110', '6394138497', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '07/04/2004', 'Technical', NULL),
(139, 'Shalini rawat', 'PBPL006107', '9650692437', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/2002', 'Customer Care', NULL),
(140, 'Simran', 'PBPL006108', '8368069817', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/01/2007', 'Admin', NULL),
(141, 'Harsh', 'PBPL006105', '9643447688', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '25/08/2002', 'Field', NULL),
(142, 'Vishakha', 'PBPL006115', '9818924188', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '14/02/2005', 'Center Phlebo', NULL),
(143, 'Saurav kumar', 'PBPL006116', '7428679875', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/01/2004', 'Technical', NULL),
(144, 'Mona', 'PBPL006104', '9871963829', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/1986', 'Housekeeping', NULL),
(145, 'Aleyamma Babu', 'PBPL006119', '9891568559', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '22/05/1973', 'Center Phlebo', NULL),
(146, 'Mansi Shukla', 'PBPL006118', '8595713150', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '25/10/2002', 'Technical', NULL),
(147, 'jyoti', 'PBPL006120', '9870554746', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/09/2003', 'Customer Care', NULL),
(148, 'Salman khan', 'PBPL006121', '9625052126', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '16/06/1999', 'Customer Care', NULL),
(149, 'Abhishek Raikwar', 'PBPL006122', '8882649327', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '16/07/2004', 'Technical', NULL),
(150, 'Naim Ahmed', 'PBPL006124', '7065310620', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '24/07/2006', 'Field', NULL),
(151, 'shama', 'PBPL006125', '9758109554', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/09/2004', 'Technical', NULL),
(152, 'dhirender singh', 'PBPL006127', '9899004178', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '03/11/1977', 'Customer Care', NULL),
(153, 'Aman', 'PBPL006131', '8448872490', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '25/02/2001', 'Technical', NULL),
(154, 'Faizan', 'PBPL006132', '7310874325', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/2006', 'Center Phlebo', NULL),
(155, 'Mohd Arif', 'PBPL006134', '7409996631', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/02/2000', 'Home Collection Phlebo', NULL),
(156, 'Pratiksha', 'PBPL006133', '9717180537', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '07/12/1998', 'Center Phlebo', NULL),
(157, 'AMRIT', 'PBPL006126', '8448234277', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/01/1987', 'Field', NULL),
(158, 'PRINCE KUMAR', 'PBPL006137', '7018048684', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '16/06/2000', 'Technical', NULL),
(159, 'FAJIL JAMALI', 'PBPL006139', '9837185025', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/07/1997', 'Home Collection Phlebo', NULL),
(160, 'Asha', 'PBPL006138', '9625982051', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/08/1999', 'House Keeping', NULL),
(161, 'Khubaib Khan', 'PBPL006140', '9540212849', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/05/1999', 'Field', NULL),
(162, 'Prashant Tiwari', 'PBPL006143', '9696983009', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '06/07/2002', 'Home Collection Phlebo', NULL),
(163, 'MD IRPHAN ALAM', 'PBPL006145', '7256934838', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '11/08/2002', 'Home Collection Phlebo', NULL),
(164, 'Karan diwakar', 'PBPL006147', '9899326035', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '18/06/2003', 'Admin', NULL),
(165, 'Suhail Ahmad', 'PBPL006141', '9625719649', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '13/08/2002', 'Field', NULL),
(166, 'Dharmendra Kumar', 'PBPL00135', '9990703607', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/05/1988', 'Home Collection Phlebo', NULL),
(167, 'Piyush Kant Pandey', 'PBPL006149', '9621991792', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/07/2025', 'Admin', NULL),
(168, 'Nurain Alam', 'PBPL006150', '8802011784', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/12/1994', 'Home Collection Phlebo', NULL),
(169, 'Imran', 'PBPL006151', '9953157867', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/12/1994', 'Home Collection Phlebo', NULL),
(170, 'Farzan Husain', 'PBPL006152', '8882392867', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '23/11/2000', 'Home Collection Phlebo', NULL),
(171, 'Srishti Bhadri', 'PBPL006154', '8287561883', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/01/2005', 'Customer Care', NULL),
(172, 'SANKET KUMAR', 'PBPL006060', '7870484426', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/04/2004', 'Technical', NULL),
(173, 'Abhay Pratap Singh', 'PBPL006155', '8077609259', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '02/08/1999', 'Home Collection Phlebo', NULL),
(174, 'Tausif Khan', 'PBPL006156', '9128271925', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/05/2003', 'Technical', NULL),
(175, 'Shubh Bhatia', 'PBPL006157', '8178444947', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '03/10/2006', 'Customer Care', NULL),
(176, 'Pankaj Kumar', 'PBPL006158', '9310013690', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '08/03/1982', 'Field', NULL),
(177, 'Nancy Dahiya', 'PBPL006159', '8950213781', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/07/2000', 'Admin', NULL),
(508, 'Vansh', 'PBPL006316', '9821226071', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '25/07/2003', 'Field', NULL),
(509, 'Rahul Kumar', 'PBPL006161', '8368402477', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/02/2003', 'Admin', NULL),
(510, 'Naveen Sagar', 'PBPL006162', '9716330697', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '16/04/1998', 'Customer Care', NULL),
(511, 'Sheetal Kumari', 'PBPL006165', '8595877546', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/10/2004', 'Technical', NULL),
(512, 'Hanzala Khan', 'PBPL006166', '7302234975', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/04/1999', 'Center Phlebo', NULL),
(513, 'Shivam Rathore', 'PBPL006169', '8882385278', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '12/04/2004', 'Admin', NULL),
(514, 'DISHIKA', 'PBPL006170', '8595614476', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/01/2003', 'Center Phlebo', NULL),
(515, 'Kanchan kumari', 'PBPL006171', '9336950360', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/09/1999', 'Technical', NULL),
(516, 'Avid Khan', 'PBPL006167', '9555231281', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '20/07/1987', 'Field', NULL),
(517, 'Pankaj Kumar', 'PBPL006173', '7042228141', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '14/05/1981', 'Field', NULL),
(518, 'Vikas', 'PBPL006175', '8800183241', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '30/07/1993', 'House Keeping', NULL),
(519, 'Suhail', 'PBPL006172', '9599356068', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '02/04/2001', 'House Keeping', NULL),
(520, 'Dilshad Ali', 'PBPL006176', '8595020105', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '08/06/1993', 'Field', NULL),
(521, 'Divyanshi Kumari', 'PBPL006177', '8929962005', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '27/06/1998', 'Center Phlebo', NULL),
(522, 'SONA', 'PBPL006178', '8076741165', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/05/2005', 'Customer Care', NULL),
(523, 'Dhiraj Kumar', 'PBPL006168', '7011372648', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/2002', 'House Keeping', NULL),
(524, 'Shalini Kumari', 'PBPL006179', '9354592130', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '20/06/2005', 'Customer Care', NULL),
(1035, 'Saddam Hussain', 'PBPL006180', '7217716998', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '12/12/1995', 'Home Collection Phlebo', NULL),
(1891, 'Harish sharma', 'PBPL006181', '9991372012', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '16/03/2000', 'Technical', NULL),
(2062, 'Tushar Kumar', 'PBPL006183', '7042384668', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '09/01/2002', 'House Keeping', NULL),
(2234, 'Rani', 'PBPL006185', '9873439864', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '07/03/2005', 'Technical', NULL),
(2235, 'Shreya', 'PBPL006186', '9958439588', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '13/01/2002', 'Technical', NULL),
(2236, 'Komal kashyap', 'PBPL006188', '9717111565', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '07/08/1996', 'Customer Care', NULL),
(2237, 'Kusum', 'PBPL006187', '8882026294', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '20/09/2003', 'Center Phlebo', NULL),
(2238, 'Prathana', 'PBPL006189', '9310240406', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/2006', 'Center Phlebo', NULL),
(2239, 'Sonia', 'PBPL006190', '7290010403', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '02/02/2002', 'Center Phlebo', NULL),
(2240, 'Shruti keshri', 'PBPL006191', '7557783359', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/08/2001', 'Technical', NULL),
(2241, 'Rohit Bisht', 'PBPL006192', '8126382045', '5', 'administrator', 1, 'Active', '2026-08-21 14:05:06', '10/04/2003', 'Admin', NULL),
(2242, 'Alok kumar singh', 'Pbpl006193', '7253017744', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '30/06/2001', 'Home Collection Phlebo', NULL),
(2243, 'Deepak Tiwari', 'PBPL006194', '7082320507', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '16/03/1998', 'Home Collection Phlebo', NULL),
(2244, 'Gaurav Kumar', 'PBPL006184', '7321992699', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '13/02/2006', 'House Keeping', NULL),
(2245, 'Jai shree gupta', 'PBPL006196', '8756419603', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/04/2004', 'Admin', NULL),
(2246, 'ATUL BABU PAL', 'PBPL006197', '9953394818', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '03/11/2005', 'Center Phlebo', NULL),
(2247, 'Deep sahani', 'PBPL006198', '9060366914', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '23/05/2005', 'Center Phlebo', NULL),
(2248, 'Rishita', 'PBPL006199', '7011721571', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/07/2005', 'Admin', NULL),
(2249, 'Shivam Dwivedi', 'PBPL006200', '9354352988', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '22/09/2002', 'Home Collection Phlebo', NULL),
(2250, 'Prerna Sharma', 'PBPL006202', '9910773271', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '25/09/1984', 'Customer Care', NULL),
(2251, 'Shyam Kumar', 'PBPL006203', '7482816592', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/2005', 'Admin', NULL),
(2252, 'Divya bisht', 'PBPL006204', '9258180594', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '27/05/2006', 'Technical', NULL),
(2253, 'Komal', 'PBPL006201', '8860886621', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '02/10/1990', 'Customer Care', NULL),
(2254, 'Sandeep', 'PBPL006205', '9560932913', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '18/11/1992', 'Field', NULL),
(2255, 'Deepak kumar', 'PBPL006206', '7210236493', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '12/02/2002', 'Home Collection Phlebo', NULL),
(2256, 'Narendra Pal', 'PBPL006207', '8077095025', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '13/01/1993', 'Home Collection Phlebo', NULL),
(2257, 'SONU MAHTO', 'PBPL006208', '8178396134', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '13/07/2000', 'Customer Care', NULL),
(2258, 'Rohan kumar giri', 'PBPL006209', '8292636187', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/01/2004', 'Home Collection Phlebo', NULL),
(2259, 'Kiran Pachori', 'PBPL006211', '9625615521', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/06/2000', 'Customer Care', NULL),
(2260, 'Sartaj Khan', 'PBPL006195', '9142276775', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/1995', 'Field', NULL),
(2261, 'Monika Rajput', 'PBPL006213', '8742945845', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '27/07/1998', 'Admin', NULL),
(2262, 'Shadab Ali', 'PBPL006210', '7088882143', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '06/07/2000', 'Home Collection Phlebo', NULL),
(2263, 'Harish Kumar', 'PBPL006211', '7011175296', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '08/07/1997', 'Home Collection Phlebo', NULL),
(2264, 'Mohd Zaid', 'PBPL006214', '6395460266', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '27/10/2003', 'Home Collection Phlebo', NULL),
(2265, 'Pritam Yadav', 'PBPL006215', '9670046193', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/07/2006', 'House Keeping', NULL),
(2266, 'Khushiya khan', 'PBPL006216', '8104091923', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/10/1994', 'Customer Care', NULL),
(2267, 'Himanshu kumar', 'PBPL006217', '8076685407', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/01/2002', 'Field', NULL),
(2268, 'Kaushik burman', 'PBPL006218', '9773877202', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/01/1993', 'Home Collection Phlebo', NULL),
(2269, 'Akash paswan', 'PBPL006219', '8882676701', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '20/11/2000', 'Home Collection Phlebo', NULL),
(2270, 'Deepak ojha', 'PBPL006220', '9310671290', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/11/2003', 'Admin', NULL),
(2271, 'Kritika Sharma', 'PBPL006223', '9650538486', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '24/10/1999', 'Technical', NULL),
(2272, 'Nishu Kumar', 'PBPL006222', '7820074697', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '09/07/2005', 'Admin', NULL),
(2273, 'Vikram', 'PBPL006224', '9871177543', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/12/2000', 'Customer Care', NULL),
(2274, 'Amit Kumar', 'PBPL006225', '9871816112', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '24/07/1988', 'Field', NULL),
(2275, 'Sonalika Barman', 'PBPL006226', '7303108169', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/12/2000', 'Customer Care', NULL),
(2276, 'Kirti kumari', 'PBPL006227', '9310005345', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/10/2001', 'Technical', NULL),
(2277, 'Sonaa', 'PBPL006228', '9315237456', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/04/2003', 'Customer Care', NULL),
(2278, 'Parveen Kumar', 'PBPL006229', '9899575280', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '03/02/1991', 'Field', NULL),
(2279, 'Ruchika sanyal', 'PBPL006230', '9953555790', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '07/07/1988', 'Customer Care', NULL),
(2280, 'Vibhor Naithani', 'PBPL006231', '7834834912', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '21/09/1995', 'Customer Care', NULL),
(2281, 'Arif Hussain', 'PBPL006232', '7352020986', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/05/2003', 'Customer Care', NULL),
(2282, 'Daniyal', 'PBPL006233', '7011427429', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '13/12/1998', 'Admin', NULL),
(2283, 'Mayanglambam Joshita Devi', 'PBPL006234', '9366205308', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/03/2002', 'Center Phlebo', NULL),
(2284, 'Ashish Bharti', 'PBPL006236', '7294933831', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '23/12/2003', 'Center Phlebo', NULL),
(2285, 'Dr. Madhusmita Samal', 'PBPL006235', '9711864683', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/12/1995', 'Technical', NULL),
(2286, 'Ms. Nisha', 'PBPL006237', '9310797080', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/04/2003', 'Center Phlebo', NULL),
(2287, 'Mohd Majid Ali', 'PBPL006238', '8826337072', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '25/05/2000', 'Customer Care', NULL),
(2289, 'Akshay Kumar', 'PBPL006241', '8882193438', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '07/06/2002', 'Admin', NULL),
(2290, 'Dr. Ashish Kumar Mandal', 'PBPL006242', '9811686403', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '29/10/1954', 'Technical', NULL),
(2291, 'Nitu', 'PBPL006243', '8130931547', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/04/2003', 'Customer Care', NULL),
(2292, 'Varun Vaidh', 'PBPL006244', '9654694176', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '23/05/2003', 'Technical', NULL),
(2293, 'Rohit Kumar', 'PBPL006245', '8076621542', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/03/2002', 'Admin', NULL),
(2294, 'Vaseem Ahmed', 'PBPL006247', '8130668574', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '22/01/1984', 'Field', NULL),
(2295, 'Richa', 'PBPL006246', '8587026915', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '29/12/1992', 'Technical', NULL),
(2296, 'KARAN JHA', 'PBPL006248', '8527115485', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/07/1996', 'Admin', NULL),
(2297, 'Mohd faizan', 'Pbpl006249', '8192008084', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/10/2001', 'Home Collection Phlebo', NULL),
(2298, 'JAYANT KUMAR', 'PBPL006250', '9761002683', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '19/03/1997', 'Customer Care', NULL),
(2299, 'Pinky Kamra', 'PBPL006251', '7827869903', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '03/12/1986', 'Customer Care', NULL),
(2300, 'TAMANNA SENGER', 'PBPL006252', '9528522090', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '09/03/2002', 'Technical', NULL),
(2301, 'RITIKA', 'PBPL006253', '9289128660', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '02/06/2005', 'Technical', NULL),
(2302, 'Sejal Rai', 'PBPL006255', '8368207989', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/09/2005', 'Customer Care', NULL),
(2303, 'Pooja Ghughtyal', 'PBPL006256', '9389159200', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '19/05/2004', 'Technical', NULL),
(2304, 'Suman', 'PBPL006254', '8368143697', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/09/1990', 'Technical', NULL),
(2305, 'Amit Kumar Gupta', 'PBPL006257', '7013842910', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/2003', 'Center Phlebo', NULL),
(2306, 'Aman Kumar', 'PBPL006259', '8920532392', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '30/08/2005', 'Admin', NULL),
(2307, 'PAWAN ARORA', 'PBPL006258', '9899231315', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/08/1967', 'Field', NULL),
(2308, 'Harvinder', 'PBPL006260', '7678241332', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/07/2004', 'Home Collection Phlebo', NULL),
(2309, 'Mohd Atif', 'PBPL006239', '8920645002', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/01/1992', 'House Keeping', NULL),
(2310, 'Tanish Kumar Singh', 'PBPL006261', '9625628264', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '23/01/2004', 'Home Collection Phlebo', NULL),
(2311, 'Radha', 'PBPL006240', '8920347044', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/09/2007', 'House Keeping', NULL),
(2312, 'Dr. Sadbhawana', 'PBPL006262', '9689768339', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/12/1992', 'Technical', NULL),
(2313, 'Ayushi', 'PBPL006266', '8810413109', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '23/12/2003', 'Technical', NULL),
(2314, 'Raj Kumar', 'Pbpl006263', '7428509786', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '07/02/2002', 'Field', NULL),
(2315, 'Prachi Baranwal', 'PBPL006265', '9968452100', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '28/12/2000', 'Technical', NULL),
(2316, 'Sanjeev kumar', 'PBPL006267', '7060718443', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/07/2004', 'Technical', NULL),
(2317, 'MANOJ KUMAR SINHA', 'PBPL006264', '9958893897', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '08/06/1985', 'Customer Care', NULL),
(2318, 'Vishal Kumar', 'PBPL006268', '9971531560', '5', 'administrator', 1, 'Active', '2026-08-21 14:14:05', '25/10/2002', 'Admin', NULL),
(2319, 'Kuldeep Kumar Rana', 'PBPL006269', '7827163364', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '23/01/1987', 'Admin', NULL),
(2320, 'Sakshi Dwivedi', 'PBPL006272', '9625412093', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/10/2005', 'Technical', NULL),
(2321, 'Nazia', 'PBPL006271', '9711237337', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '23/03/2005', 'Technical', NULL),
(2322, 'Karishma Thapa', 'PBPL006270', '9810139947', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '31/12/2000', 'Customer Care', NULL),
(2323, 'Rajiv Kumar', 'PBPL006273', '8920400030', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '11/04/1978', 'Field', NULL),
(2324, 'Nazia', 'PBPL006271', '9711237334', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '23/03/2005', 'Technical', NULL),
(2325, 'Raja kumar ram', 'PBPL006274', '7303703062', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '11/03/1997', 'Admin', NULL),
(2326, 'Raja kumar ram', 'PBPL006274', '7303103062', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '11/03/1997', 'Admin', NULL),
(2327, 'Yash kumar', 'PBPL006273', '9911442576', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/12/2004', 'Field', NULL),
(2328, 'BACHCHU SINGH', 'PBPL006275', '7900627176', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/05/1992', 'Technical', NULL),
(2329, 'Moh salman', 'PBPL006276', '7703888893', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '05/05/2003', 'Home Collection Phlebo', NULL),
(2330, 'Nazim Saifi', 'PBPL006279', '9873634167', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '07/02/1998', 'Home Collection Phlebo', NULL),
(2331, 'Shikeb shikeb', 'PBPL006277', '9599672882', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '29/11/1999', 'Field', NULL),
(2332, 'Waseem Ahmad', 'PBPL006278', '9310409415', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/03/1999', 'Home Collection Phlebo', NULL),
(2333, 'Dr. Priyanka Rana', 'PBPL006280', '7982499980', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/07/1981', 'Technical', NULL),
(2334, 'Krishna Yadav', 'PBPL006281', '9910798049', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '20/08/2003', 'Technical', NULL),
(2335, 'Rukaiya', 'PBPL006283', '9205088958', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/12/1996', 'Customer Care', NULL),
(2336, 'SALMAN', 'PBPL006282', '9643365081', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '28/01/1996', 'Technical', NULL),
(2337, 'Dr. Priyanka Rana', 'PBPL006280', '8860211191', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/07/1981', 'Technical', NULL),
(2338, 'Neelam', 'PBPL006285', '9910368728', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/11/1992', 'Admin', NULL),
(2339, 'Dr. Mohan Vashistha', 'PBPL006286', '9717561139', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/08/1994', 'Technical', NULL),
(2340, 'Shabnam khan', 'PBPL006287', '9818393041', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '07/07/1992', 'Customer Care', NULL),
(2341, 'Md Anas', 'PBPL006288', '8285846463', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/07/2000', 'Customer Care', NULL),
(2342, 'Devki', 'PBPL006289', '9818784918', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/01/1987', 'House Keeping', NULL),
(2343, 'Md Rahmatullha', 'PBPL00431', '7482077521', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/03/2002', 'Home Collection Phlebo', NULL),
(2344, 'Seruodin Khan', 'PBPL006295', '9990876132', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/06/1999', 'House Keeping', NULL),
(2345, 'Ritika', 'PBPL006296', '7678413070', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '02/06/2001', 'Center Phlebo', NULL),
(2346, 'Mohd kaif', 'PBPL006297', '7505452526', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/2005', 'Center Phlebo', NULL),
(2347, 'Tamanna', 'PBPL006294', '8588019473', '2', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/07/2007', 'House Keeping', NULL),
(2348, 'Amit kumar', 'PBPL006284', '6280273178', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/12/1992', 'Field', NULL),
(2349, 'Akash Kumar', 'PBPL006298', '7479848162', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '17/11/1999', 'Center Phlebo', NULL),
(2350, 'Rahul Kumar', 'PBPL006299', '8789959708', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '10/12/2000', 'Home Collection Phlebo', NULL),
(2351, 'Md Shaheed Alam', 'PBPL006302', '7011857480', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/06/1972', 'Home Collection Phlebo', NULL),
(2352, 'Siddharth Gautam', 'PBPL006303', '8076429246', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/10/2000', 'Home Collection Phlebo', NULL),
(2353, 'Tanu Thakur', 'PBPL006304', '9457193691', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/06/2002', 'Home Collection Phlebo', NULL),
(2354, 'Subhojit Bhowmick', 'PBPL006301', '9716228507', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '07/06/1983', 'Field', NULL),
(2355, 'Vipin Uniyal', 'PBPL006315', '7827891918', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '04/08/1995', 'Home Collection Phlebo', NULL),
(2356, 'Aasif', 'PBPL006306', '8076456979', '5,6', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '24/01/1996', 'Home Collection Phlebo', NULL),
(2357, 'Kunal taak', 'PBPL006307', '7982267099', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '23/02/2002', 'Admin', NULL),
(2358, 'Shivam', 'PBPL006308', '9711075135', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '15/07/1996', 'Customer Care', NULL),
(2359, 'Ashish Kumar', 'PBPL006310', '9336224942', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '20/02/2003', 'Technical', NULL),
(2360, 'Rahul', 'PBPL006312', '7217406085', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '24/10/2001', 'Home Collection Phlebo', NULL),
(2361, 'Chanchal kumar jha', 'PBPL006311', '9199431331', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '01/11/1990', 'Marketing', NULL),
(2362, 'Bhavana', 'PBPL006314', '9643116536', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '09/03/1996', 'Admin', NULL),
(2363, 'Neha Kushwaha', 'PBPL006317', '8272993570', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '26/04/2003', 'Center Phlebo', NULL),
(2364, 'Bhawana Manral', 'PBPL006319', '6398831177', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/03/2005', 'Admin', NULL),
(2365, 'Radhika Beniwal', 'PBPL006318', '8920710882', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '29/06/1999', 'Center Phlebo', NULL),
(2366, 'Kartikay', 'PBPL006321', '9818505251', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '22/10/2006', 'Field', NULL),
(2367, 'Masum', 'PBPL006322', '9934473588', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '24/02/2002', 'Field', NULL),
(2368, 'Mohit', 'PBPL006320', '9711764003', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '13/08/1999', 'Field', NULL),
(2369, 'MD.Samad Khan', 'PBPL006330', '7897612321', '5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '02/08/1997', 'Customer Care', NULL),
(2370, 'Dilshad Shaikh', 'PBPL006324', '9451039979', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '25/08/1986', 'Admin', NULL),
(2371, 'Arvind Kumar raikwar', 'PBPL006325', '9315928491', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/06/1985', 'Field', NULL),
(2372, 'BHARAT VERMA', 'PBPL006327', '9821418170', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/07/1983', 'Field', NULL),
(2373, 'Balbir Chauhan', 'PBPL006323', '7703928856', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/1988', 'Field', NULL),
(2374, 'Umesh', 'PBPL006326', '9315598026', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '11/11/1998', 'Field', NULL),
(2375, 'Vinay kumar', 'PBPL006328', '9910807645', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/07/1983', 'Field', NULL),
(2376, 'Sanjeev Kumar dass', 'PBPL006329', '9599586359', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '25/09/1991', 'Admin', NULL),
(2377, 'Rahul gill', 'PBPL006333', '7042961384', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/04/1996', 'House Keeping', NULL),
(2378, 'Gagan kumar', 'PBPL006335', '7701820930', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/04/2004', 'Admin', NULL),
(2379, 'Surendra kumar', 'PBPL006336', '8377072771', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/07/1999', 'Field', NULL),
(2380, 'Premavati', 'PBPL006337', '8368212830', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '18/01/1990', 'Center Phlebo', NULL),
(2381, 'Sanjeev Kumar Chauhan', 'PBPL006339', '9315269694', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/09/1978', 'House Keeping', NULL),
(2382, 'Niraj Kumar Ram', 'PBPL006340', '9211586197', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '12/05/2000', 'House Keeping', NULL),
(2383, 'Ajay kumar', 'PBPL006341', '8178870256', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '16/07/1997', 'Field', NULL),
(2384, 'DILEEP KUMAR SETHI', 'PPBL006342', '8650200563', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '24/03/1995', 'Home Collection Phlebo', NULL),
(2385, 'Pushpendra Kumar', 'PBPL006343', '9557032113', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '05/06/1998', 'Home Collection Phlebo', NULL),
(2386, 'Obaid ur rehman', 'PBPL006345', '9315426282', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '20/03/2002', 'Home Collection Phlebo', NULL),
(2387, 'Akash Goswami', 'PBPL006344', '8447385429', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '12/09/1977', 'Center Phlebo', NULL),
(2388, 'Parul Jauhar', 'PBPL006346', '8375007870', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '28/10/1978', 'Admin', NULL),
(2389, 'Nitin Kumar', 'PBPL006347', '9259822281', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/07/1993', 'Home Collection Phlebo', NULL),
(2390, 'Kapil', 'PBPL006348', '9821382122', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '18/08/1996', 'Home Collection Phlebo', NULL),
(2391, 'Nibha', 'PBPL006349', '9560817948', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '02/05/2004', 'Customer Care', NULL),
(2392, 'Abhishek Sharma', 'PBPL006350', '7011630322', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '26/09/1980', 'Marketing', NULL),
(2393, 'Devender Kumar', 'PBPL006351', '9773865082', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '30/01/1982', 'Marketing', NULL),
(2394, 'Harshdeep', 'PBPL006352', '6230310396', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '09/05/2005', 'Admin', NULL),
(2395, 'ANUJ AGRAAHARI', 'PBPL006353', '8527062561', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '19/01/2008', 'House Keeping', NULL);
INSERT INTO `users` (`id`, `name`, `password`, `contact`, `departments`, `role`, `role_id`, `status`, `last_updated`, `dob`, `designation`, `department_id`) VALUES
(2396, 'Hifza Ahmed', 'PBPL006355', '6395952306', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '20/05/2000', 'Technical', NULL),
(2397, 'kiran', 'PBPL006356', '9717984387', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/01/1995', 'House Keeping', NULL),
(2398, 'VIJAY SINGH RAWAT', 'PBPL00417', '8851485941', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '03/09/1990', 'Home Collection Phlebo', NULL),
(2399, 'Shoeb Alam', 'PBPL006358', '7982209598', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '28/10/1999', 'Customer Care', NULL),
(2400, 'Alka Kumari Singh', 'PBPL006359', '9366395918', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/09/1994', 'Center Phlebo', NULL),
(2401, 'Mayank Chauhan', 'PBPL006360', '9548659631', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '17/05/2005', 'Home Collection Phlebo', NULL),
(2402, 'Rishu Sharma', 'PBPL00420', '9310733107', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '07/07/2003', 'Technical', NULL),
(2403, 'Monika', 'PBPL00421', '7522042657', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '03/11/2001', 'Customer Care', NULL),
(2404, 'Surjeet Singh Rawat', 'PBPL00422', '7701961954', '5', 'administrator', 1, 'Active', '2026-08-24 07:40:38', '12/05/1976', 'Admin', NULL),
(2405, 'Mohd Zaki', 'PBPL00423', '8077250258', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '15/12/2000', 'Home Collection Phlebo', NULL),
(2406, 'SHIVANI', 'PBPL00430', '9220429072', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '22/11/2005', 'House Keeping', NULL),
(2407, 'Nikita tawar', 'PBPL00427', '9971229084', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '27/11/2002', 'Center Phlebo', NULL),
(2408, 'Chandan Jha', 'PBPL00428', '9958593916', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/03/1993', 'Admin', NULL),
(2409, 'Suraj Thakur', 'PBPL00429', '9643175702', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '01/04/2001', 'Technical', NULL),
(2410, 'Mohd Kaif', 'PBPL00434', '8287808475', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '10/08/2002', 'Center Phlebo', NULL),
(2411, 'Deepa', 'PBPL00436', '8595236105', '1,6,5', 'employee', 7, 'Inactive', '2026-08-21 14:08:18', '22/12/2000', 'Technical', NULL),
(2412, 'Harsh bhadouriya', 'PBPL00437', '9473554990', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/02/2006', 'Technical', NULL),
(2413, 'Suraj Kumar', 'PBPL00445', '9582420527', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '03/06/1998', 'Customer Care', NULL),
(2414, 'Rohit Mani', 'PBPL00443', '9310565062', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '26/10/1992', 'Customer Care', NULL),
(2415, 'Shifa', 'PBPL00440', '9318315461', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '16/07/1997', 'Technical', NULL),
(2416, 'shailendra kumar', 'PBPL00442', '8882152935', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '07/07/1987', 'Technical', NULL),
(2417, 'Rajan', 'PBPL00446', '7007612135', '5,6', 'employee', 7, 'Active', '2026-08-21 14:08:18', '11/12/2003', 'Center Phlebo', NULL),
(2418, 'Md Irfan Khan', 'PBPL00447', '8271608432', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '04/03/1994', 'Technical', NULL),
(2419, 'SAQLAIN RAZA REHMANI', 'PBPL00448', '9142263665', '1,6,5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '11/09/2003', 'Technical', NULL),
(2420, 'Kapil verma', 'PBPL00449', '8448335612', '5', 'employee', 7, 'Active', '2026-08-21 14:08:18', '14/03/2000', 'Field', NULL),
(2421, 'ROHIT KUMAR', 'PBPL00450', '9958594485', '2', 'employee', 7, 'Active', '2026-08-21 14:08:18', '08/04/2004', 'House Keeping', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `users_legacy_auth_20260821`
--

CREATE TABLE `users_legacy_auth_20260821` (
  `id` bigint(20) NOT NULL,
  `username` varchar(80) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `must_change_password` tinyint(1) NOT NULL,
  `role_id` bigint(20) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users_legacy_auth_20260821`
--

INSERT INTO `users_legacy_auth_20260821` (`id`, `username`, `password_hash`, `must_change_password`, `role_id`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'admin', '$pbkdf2-sha256$29000$FQLA2Ls35lwr5RzjnFNq7Q$FVvQSXSCyHhuJ3HaVCXujEv3VODR8vMs92YwGSHkOho', 1, 1, 1, '2026-08-20 11:53:55', '2026-08-20 11:53:55'),
(2, 'asset.manager', '$pbkdf2-sha256$29000$b.2d8z4HIERo7d0bIwSg1A$A4QJXIZM/8l9ns./CjBJdPynHMSSTH0G96nnjPM84x0', 0, 3, 1, '2026-08-21 12:35:37', '2026-08-21 12:35:37'),
(3, 'asset.coordinator', '$pbkdf2-sha256$29000$T0kpZQyhNOZ8b42x9r63dg$viFx80foewPopfQWLG2ENaJ3pZrl0GcF4tLJuoE.WKQ', 0, 7, 1, '2026-08-21 12:35:37', '2026-08-21 12:35:37'),
(4, 'technician', '$pbkdf2-sha256$29000$mHOOsVZqDQHAWCtFaK2VMg$GoMeM0OKgULMIeyOJz07e.k4WYlr1tZJrjz204IyaUk', 0, 2, 1, '2026-08-21 12:35:37', '2026-08-21 12:35:37'),
(5, 'service.engineer', '$pbkdf2-sha256$29000$J2SsdW6t1bq3VgoBgND6/w$nfgV7PU5bv1IpHsu5a7YaCtxLU.9l4H7ljOsRH0ychM', 0, 7, 1, '2026-08-21 12:35:37', '2026-08-21 12:35:37'),
(6, 'management', '$pbkdf2-sha256$29000$ZCxlbK1VirG2Voqx9l5r7Q$rGAxr8NiQ77brU8ieW1EEx527EDs1ie.fVl6fAWWwEI', 0, 7, 1, '2026-08-21 12:35:37', '2026-08-21 12:35:37'),
(7, 'employee', '$pbkdf2-sha256$29000$ei/lnJOS0tpb610LQUgJ4Q$XOKONdS2XHlhrHpaMcUvb0DWNf4T8Q/.Kqo99K8BhHE', 0, 7, 1, '2026-08-21 12:35:37', '2026-08-21 12:35:37');

-- --------------------------------------------------------

--
-- Table structure for table `vendors`
--

CREATE TABLE `vendors` (
  `id` bigint(20) NOT NULL,
  `company_name` varchar(200) NOT NULL,
  `address` text DEFAULT NULL,
  `gstin` varchar(30) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `whatsapp` varchar(30) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `vendors`
--

INSERT INTO `vendors` (`id`, `company_name`, `address`, `gstin`, `phone`, `whatsapp`, `email`, `notes`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Demo Service Partners', NULL, NULL, '8126382045', NULL, NULL, NULL, 1, '2026-08-20 11:53:55', '2026-08-24 10:03:11');

-- --------------------------------------------------------

--
-- Table structure for table `vendor_roles`
--

CREATE TABLE `vendor_roles` (
  `id` bigint(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vendor_role_links`
--

CREATE TABLE `vendor_role_links` (
  `vendor_id` bigint(20) NOT NULL,
  `role_id` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `workstations`
--

CREATE TABLE `workstations` (
  `id` bigint(20) NOT NULL,
  `name` varchar(150) NOT NULL,
  `department_id` bigint(20) DEFAULT NULL,
  `site_id` bigint(20) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `workstations`
--

INSERT INTO `workstations` (`id`, `name`, `department_id`, `site_id`, `is_active`, `created_at`, `updated_at`) VALUES
(2, 'Basement', 6, 1, 1, '2026-08-24 07:23:44', '2026-08-24 07:23:44'),
(3, 'Surjeet Rawat', 6, 1, 1, '2026-08-24 07:24:39', '2026-08-24 07:24:39'),
(4, 'Basement', 6, 1, 1, '2026-08-24 07:25:16', '2026-08-24 07:25:16'),
(5, 'Workstation', 6, 1, 1, '2026-08-24 07:25:30', '2026-08-24 07:25:30'),
(6, 'Administration', 6, 1, 1, '2026-08-24 07:26:03', '2026-08-24 07:26:03'),
(7, 'BASEMENT', 6, 1, 1, '2026-08-24 07:44:13', '2026-08-24 07:44:13'),
(8, 'Basement', 6, 1, 1, '2026-08-27 06:07:54', '2026-08-27 06:07:54'),
(9, 'BASEMENT', 6, 1, 1, '2026-08-27 06:28:00', '2026-08-27 06:28:00');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `approval_requests`
--
ALTER TABLE `approval_requests`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `approval_number` (`approval_number`),
  ADD KEY `asset_id` (`asset_id`);

--
-- Indexes for table `assets`
--
ALTER TABLE `assets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_assets_asset_code` (`asset_code`),
  ADD UNIQUE KEY `ix_assets_public_token` (`public_token`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `asset_type_id` (`asset_type_id`),
  ADD KEY `make_id` (`make_id`),
  ADD KEY `current_floor_id` (`current_floor_id`),
  ADD KEY `current_department_id` (`current_department_id`),
  ADD KEY `current_workstation_id` (`current_workstation_id`),
  ADD KEY `staff_incharge_employee_id` (`staff_incharge_employee_id`),
  ADD KEY `issued_to_employee_id` (`issued_to_employee_id`),
  ADD KEY `primary_service_contact_id` (`primary_service_contact_id`),
  ADD KEY `ix_assets_filters` (`current_site_id`,`operational_status`,`criticality`),
  ADD KEY `ix_assets_serial_number` (`serial_number`);

--
-- Indexes for table `asset_alerts`
--
ALTER TABLE `asset_alerts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_asset_alerts_asset_id` (`asset_id`),
  ADD KEY `ix_asset_alerts_alert_type` (`alert_type`),
  ADD KEY `ix_asset_alerts_status` (`status`);

--
-- Indexes for table `asset_categories`
--
ALTER TABLE `asset_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_asset_categories_name` (`name`);

--
-- Indexes for table `asset_documents`
--
ALTER TABLE `asset_documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_asset_documents_asset_id` (`asset_id`);

--
-- Indexes for table `asset_events`
--
ALTER TABLE `asset_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_asset_events_asset_id` (`asset_id`);

--
-- Indexes for table `asset_incharge_history`
--
ALTER TABLE `asset_incharge_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `employee_id` (`employee_id`),
  ADD KEY `ix_asset_incharge_history_asset_id` (`asset_id`);

--
-- Indexes for table `asset_issue_history`
--
ALTER TABLE `asset_issue_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `employee_id` (`employee_id`),
  ADD KEY `ix_asset_issue_history_asset_id` (`asset_id`);

--
-- Indexes for table `asset_location_history`
--
ALTER TABLE `asset_location_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `site_id` (`site_id`),
  ADD KEY `floor_id` (`floor_id`),
  ADD KEY `department_id` (`department_id`),
  ADD KEY `workstation_id` (`workstation_id`),
  ADD KEY `ix_asset_location_history_asset_id` (`asset_id`);

--
-- Indexes for table `asset_makes`
--
ALTER TABLE `asset_makes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_asset_makes_name` (`name`);

--
-- Indexes for table `asset_service_contacts`
--
ALTER TABLE `asset_service_contacts`
  ADD PRIMARY KEY (`asset_id`,`contact_id`),
  ADD KEY `contact_id` (`contact_id`);

--
-- Indexes for table `asset_types`
--
ALTER TABLE `asset_types`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `category_id` (`category_id`,`name`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `calibration_records`
--
ALTER TABLE `calibration_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_calibration_records_schedule_id` (`schedule_id`);

--
-- Indexes for table `calibration_schedules`
--
ALTER TABLE `calibration_schedules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `asset_id` (`asset_id`),
  ADD KEY `vendor_id` (`vendor_id`);

--
-- Indexes for table `contract_renewals`
--
ALTER TABLE `contract_renewals`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_contract_renewals_approval_id` (`approval_id`),
  ADD KEY `ix_contract_renewals_contract_id` (`contract_id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_departments_name` (`name`),
  ADD KEY `floor_id` (`floor_id`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `employee_code` (`employee_code`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `external_movements`
--
ALTER TABLE `external_movements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `gate_pass_number` (`gate_pass_number`),
  ADD KEY `vendor_id` (`vendor_id`),
  ADD KEY `ix_external_movements_asset_id` (`asset_id`);

--
-- Indexes for table `floors`
--
ALTER TABLE `floors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `site_id` (`site_id`,`name`);

--
-- Indexes for table `number_sequences`
--
ALTER TABLE `number_sequences`
  ADD PRIMARY KEY (`key`);

--
-- Indexes for table `pm_records`
--
ALTER TABLE `pm_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `schedule_id` (`schedule_id`);

--
-- Indexes for table `pm_schedules`
--
ALTER TABLE `pm_schedules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `asset_id` (`asset_id`),
  ADD KEY `provider_vendor_id` (`provider_vendor_id`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `service_contacts`
--
ALTER TABLE `service_contacts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `vendor_id` (`vendor_id`);

--
-- Indexes for table `service_contracts`
--
ALTER TABLE `service_contracts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `contract_number` (`contract_number`),
  ADD KEY `vendor_id` (`vendor_id`);

--
-- Indexes for table `service_contract_assets`
--
ALTER TABLE `service_contract_assets`
  ADD PRIMARY KEY (`contract_id`,`asset_id`),
  ADD KEY `asset_id` (`asset_id`);

--
-- Indexes for table `service_tickets`
--
ALTER TABLE `service_tickets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_service_tickets_ticket_number` (`ticket_number`),
  ADD KEY `vendor_id` (`vendor_id`),
  ADD KEY `ix_service_tickets_asset_id` (`asset_id`);

--
-- Indexes for table `service_ticket_events`
--
ALTER TABLE `service_ticket_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_service_ticket_events_ticket_id` (`ticket_id`);

--
-- Indexes for table `service_ticket_parts`
--
ALTER TABLE `service_ticket_parts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ticket_id` (`ticket_id`);

--
-- Indexes for table `sites`
--
ALTER TABLE `sites`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_sites_name` (`name`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_contact` (`contact`),
  ADD KEY `ix_users_role_id` (`role_id`);

--
-- Indexes for table `users_legacy_auth_20260821`
--
ALTER TABLE `users_legacy_auth_20260821`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_users_username` (`username`),
  ADD KEY `role_id` (`role_id`);

--
-- Indexes for table `vendors`
--
ALTER TABLE `vendors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `company_name` (`company_name`);

--
-- Indexes for table `vendor_roles`
--
ALTER TABLE `vendor_roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_vendor_roles_name` (`name`);

--
-- Indexes for table `vendor_role_links`
--
ALTER TABLE `vendor_role_links`
  ADD PRIMARY KEY (`vendor_id`,`role_id`),
  ADD KEY `role_id` (`role_id`);

--
-- Indexes for table `workstations`
--
ALTER TABLE `workstations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `department_id` (`department_id`),
  ADD KEY `site_id` (`site_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `approval_requests`
--
ALTER TABLE `approval_requests`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `assets`
--
ALTER TABLE `assets`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_alerts`
--
ALTER TABLE `asset_alerts`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_categories`
--
ALTER TABLE `asset_categories`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `asset_documents`
--
ALTER TABLE `asset_documents`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_events`
--
ALTER TABLE `asset_events`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_incharge_history`
--
ALTER TABLE `asset_incharge_history`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_issue_history`
--
ALTER TABLE `asset_issue_history`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_location_history`
--
ALTER TABLE `asset_location_history`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `asset_makes`
--
ALTER TABLE `asset_makes`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `asset_types`
--
ALTER TABLE `asset_types`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `calibration_records`
--
ALTER TABLE `calibration_records`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `calibration_schedules`
--
ALTER TABLE `calibration_schedules`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `contract_renewals`
--
ALTER TABLE `contract_renewals`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=126;

--
-- AUTO_INCREMENT for table `external_movements`
--
ALTER TABLE `external_movements`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `floors`
--
ALTER TABLE `floors`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `pm_records`
--
ALTER TABLE `pm_records`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pm_schedules`
--
ALTER TABLE `pm_schedules`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `service_contacts`
--
ALTER TABLE `service_contacts`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `service_contracts`
--
ALTER TABLE `service_contracts`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_tickets`
--
ALTER TABLE `service_tickets`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_ticket_events`
--
ALTER TABLE `service_ticket_events`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service_ticket_parts`
--
ALTER TABLE `service_ticket_parts`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sites`
--
ALTER TABLE `sites`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2422;

--
-- AUTO_INCREMENT for table `users_legacy_auth_20260821`
--
ALTER TABLE `users_legacy_auth_20260821`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `vendors`
--
ALTER TABLE `vendors`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `vendor_roles`
--
ALTER TABLE `vendor_roles`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `workstations`
--
ALTER TABLE `workstations`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `approval_requests`
--
ALTER TABLE `approval_requests`
  ADD CONSTRAINT `approval_requests_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`);

--
-- Constraints for table `assets`
--
ALTER TABLE `assets`
  ADD CONSTRAINT `assets_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `asset_categories` (`id`),
  ADD CONSTRAINT `assets_ibfk_10` FOREIGN KEY (`primary_service_contact_id`) REFERENCES `service_contacts` (`id`),
  ADD CONSTRAINT `assets_ibfk_2` FOREIGN KEY (`asset_type_id`) REFERENCES `asset_types` (`id`),
  ADD CONSTRAINT `assets_ibfk_3` FOREIGN KEY (`make_id`) REFERENCES `asset_makes` (`id`),
  ADD CONSTRAINT `assets_ibfk_4` FOREIGN KEY (`current_site_id`) REFERENCES `sites` (`id`),
  ADD CONSTRAINT `assets_ibfk_5` FOREIGN KEY (`current_floor_id`) REFERENCES `floors` (`id`),
  ADD CONSTRAINT `assets_ibfk_6` FOREIGN KEY (`current_department_id`) REFERENCES `departments` (`id`),
  ADD CONSTRAINT `assets_ibfk_7` FOREIGN KEY (`current_workstation_id`) REFERENCES `workstations` (`id`),
  ADD CONSTRAINT `assets_ibfk_8` FOREIGN KEY (`staff_incharge_employee_id`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `assets_ibfk_9` FOREIGN KEY (`issued_to_employee_id`) REFERENCES `employees` (`id`);

--
-- Constraints for table `asset_alerts`
--
ALTER TABLE `asset_alerts`
  ADD CONSTRAINT `asset_alerts_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`);

--
-- Constraints for table `asset_documents`
--
ALTER TABLE `asset_documents`
  ADD CONSTRAINT `asset_documents_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`);

--
-- Constraints for table `asset_events`
--
ALTER TABLE `asset_events`
  ADD CONSTRAINT `asset_events_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`);

--
-- Constraints for table `asset_incharge_history`
--
ALTER TABLE `asset_incharge_history`
  ADD CONSTRAINT `asset_incharge_history_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `asset_incharge_history_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`);

--
-- Constraints for table `asset_issue_history`
--
ALTER TABLE `asset_issue_history`
  ADD CONSTRAINT `asset_issue_history_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `asset_issue_history_ibfk_2` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`);

--
-- Constraints for table `asset_location_history`
--
ALTER TABLE `asset_location_history`
  ADD CONSTRAINT `asset_location_history_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `asset_location_history_ibfk_2` FOREIGN KEY (`site_id`) REFERENCES `sites` (`id`),
  ADD CONSTRAINT `asset_location_history_ibfk_3` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`),
  ADD CONSTRAINT `asset_location_history_ibfk_4` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`),
  ADD CONSTRAINT `asset_location_history_ibfk_5` FOREIGN KEY (`workstation_id`) REFERENCES `workstations` (`id`);

--
-- Constraints for table `asset_service_contacts`
--
ALTER TABLE `asset_service_contacts`
  ADD CONSTRAINT `asset_service_contacts_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `asset_service_contacts_ibfk_2` FOREIGN KEY (`contact_id`) REFERENCES `service_contacts` (`id`);

--
-- Constraints for table `asset_types`
--
ALTER TABLE `asset_types`
  ADD CONSTRAINT `asset_types_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `asset_categories` (`id`);

--
-- Constraints for table `calibration_records`
--
ALTER TABLE `calibration_records`
  ADD CONSTRAINT `calibration_records_ibfk_1` FOREIGN KEY (`schedule_id`) REFERENCES `calibration_schedules` (`id`);

--
-- Constraints for table `calibration_schedules`
--
ALTER TABLE `calibration_schedules`
  ADD CONSTRAINT `calibration_schedules_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `calibration_schedules_ibfk_2` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `contract_renewals`
--
ALTER TABLE `contract_renewals`
  ADD CONSTRAINT `contract_renewals_ibfk_1` FOREIGN KEY (`contract_id`) REFERENCES `service_contracts` (`id`),
  ADD CONSTRAINT `contract_renewals_ibfk_2` FOREIGN KEY (`approval_id`) REFERENCES `approval_requests` (`id`);

--
-- Constraints for table `departments`
--
ALTER TABLE `departments`
  ADD CONSTRAINT `departments_ibfk_1` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`);

--
-- Constraints for table `employees`
--
ALTER TABLE `employees`
  ADD CONSTRAINT `employees_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`);

--
-- Constraints for table `external_movements`
--
ALTER TABLE `external_movements`
  ADD CONSTRAINT `external_movements_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `external_movements_ibfk_2` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `floors`
--
ALTER TABLE `floors`
  ADD CONSTRAINT `floors_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `sites` (`id`);

--
-- Constraints for table `pm_records`
--
ALTER TABLE `pm_records`
  ADD CONSTRAINT `pm_records_ibfk_1` FOREIGN KEY (`schedule_id`) REFERENCES `pm_schedules` (`id`);

--
-- Constraints for table `pm_schedules`
--
ALTER TABLE `pm_schedules`
  ADD CONSTRAINT `pm_schedules_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `pm_schedules_ibfk_2` FOREIGN KEY (`provider_vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `service_contacts`
--
ALTER TABLE `service_contacts`
  ADD CONSTRAINT `service_contacts_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `service_contracts`
--
ALTER TABLE `service_contracts`
  ADD CONSTRAINT `service_contracts_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `service_contract_assets`
--
ALTER TABLE `service_contract_assets`
  ADD CONSTRAINT `service_contract_assets_ibfk_1` FOREIGN KEY (`contract_id`) REFERENCES `service_contracts` (`id`),
  ADD CONSTRAINT `service_contract_assets_ibfk_2` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`);

--
-- Constraints for table `service_tickets`
--
ALTER TABLE `service_tickets`
  ADD CONSTRAINT `service_tickets_ibfk_1` FOREIGN KEY (`asset_id`) REFERENCES `assets` (`id`),
  ADD CONSTRAINT `service_tickets_ibfk_2` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `service_ticket_events`
--
ALTER TABLE `service_ticket_events`
  ADD CONSTRAINT `service_ticket_events_ibfk_1` FOREIGN KEY (`ticket_id`) REFERENCES `service_tickets` (`id`);

--
-- Constraints for table `service_ticket_parts`
--
ALTER TABLE `service_ticket_parts`
  ADD CONSTRAINT `service_ticket_parts_ibfk_1` FOREIGN KEY (`ticket_id`) REFERENCES `service_tickets` (`id`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_role_id` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`);

--
-- Constraints for table `users_legacy_auth_20260821`
--
ALTER TABLE `users_legacy_auth_20260821`
  ADD CONSTRAINT `users_legacy_auth_20260821_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`);

--
-- Constraints for table `vendor_role_links`
--
ALTER TABLE `vendor_role_links`
  ADD CONSTRAINT `vendor_role_links_ibfk_1` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`),
  ADD CONSTRAINT `vendor_role_links_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `vendor_roles` (`id`);

--
-- Constraints for table `workstations`
--
ALTER TABLE `workstations`
  ADD CONSTRAINT `workstations_ibfk_1` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`),
  ADD CONSTRAINT `workstations_ibfk_2` FOREIGN KEY (`site_id`) REFERENCES `sites` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
