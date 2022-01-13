-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 13, 2022 at 05:14 PM
-- Server version: 10.4.18-MariaDB
-- PHP Version: 8.0.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sklep_internertowy`
--
CREATE DATABASE IF NOT EXISTS `sklep_internertowy` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `sklep_internertowy`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `AddItemForSale`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddItemForSale` (IN `seller_id` INT, IN `item_name` VARCHAR(255), IN `item_desc` TEXT, IN `item_price` DOUBLE, IN `item_amount` INT)  NO SQL
BEGIN
INSERT INTO item
VALUES (NULL,
       item_name, item_desc, seller_id,
       item_price, item_amount);
SELECT LAST_ID('item');
END$$

DROP PROCEDURE IF EXISTS `AddItemToRequest`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddItemToRequest` (IN `in_client_id` INT(11), IN `in_item_id` BIGINT(20), IN `in_amount` INT(11))  BEGIN
    SET @owner = (SELECT Owner FROM item WHERE Id = in_item_id);
    SET @req = (SELECT Id FROM request WHERE request.Seller_Id = @owner AND request.Client_Id = in_client_id LIMIT 1);
    IF @req IS NULL THEN
        INSERT INTO request(Seller_Id, Client_Id) VALUES(@owner, in_client_id);
        INSERT INTO shipment VALUES(in_item_id, (SELECT LAST_ID('request')), in_amount);
    ELSE
        IF in_item_id IN (SELECT Item_Id FROM shipment WHERE Request_Id = @req) THEN
            UPDATE shipment SET Amount = Amount + in_amount;
        ELSE
            INSERT INTO shipment VALUES(in_item_id, @req, in_amount);
        END IF;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `DeleteItemFromRequest`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteItemFromRequest` (IN `in_client_id` INT(11), IN `in_item_id` BIGINT(20))  BEGIN
    SET @owner = (SELECT Owner FROM item WHERE Id = in_item_id LIMIT 1);
    SET @req = (SELECT Id FROM request WHERE request.Seller_Id = @owner AND request.Client_Id = in_client_id LIMIT 1);

    DELETE FROM shipment WHERE Item_Id = in_item_id AND Request_Id = @req;
END$$

DROP PROCEDURE IF EXISTS `DeleteItemFromSale`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteItemFromSale` (IN `in_seller_id` INT(11), IN `in_item_id` BIGINT(20))  BEGIN
    DELETE FROM item WHERE Owner = in_seller_id AND Id = in_item_id;
END$$

DROP PROCEDURE IF EXISTS `ExecuteRequest`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ExecuteRequest` (IN `req_id` BIGINT(20))  BEGIN
    IF (req_id IN (SELECT Id From request)) THEN
    	SET autocommit = 0;
        START TRANSACTION;
        DELETE FROM request WHERE Id = req_id;
        COMMIT;
        SET autocommit = 1;  
    END IF;
END$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `check_request_correctness`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `check_request_correctness` (`req_id` BIGINT(20), `sel_id` INT(11)) RETURNS TINYINT(1) BEGIN
   IF (SELECT MIN(Amount_In_Stock - shipment.Amount)
   FROM item INNER JOIN shipment ON item.id = shipment.Item_Id WHERE Request_Id = req_id AND item.owner = sel_id)
   < 0 THEN RETURN FALSE; end if;
   RETURN TRUE;
END$$

DROP FUNCTION IF EXISTS `LAST_ID`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `LAST_ID` (`my_table_name` VARCHAR(255)) RETURNS BIGINT(20) BEGIN
    DECLARE number INT;
   	SELECT AUTO_INCREMENT INTO number
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = my_table_name;
    RETURN number - 1;
    END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `client`
--

DROP TABLE IF EXISTS `client`;
CREATE TABLE `client` (
  `Id` int(11) NOT NULL,
  `Username` varchar(20) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Surname` varchar(255) NOT NULL,
  `Country` int(11) NOT NULL,
  `Balance` decimal(24,2) NOT NULL DEFAULT 0.00,
  `Phone` varchar(255) DEFAULT NULL,
  `EMail` varchar(255) DEFAULT NULL,
  `Passwd` varchar(255) NOT NULL
) ;

--
-- Dumping data for table `client`
--

INSERT INTO `client` (`Id`, `Username`, `Name`, `Surname`, `Country`, `Balance`, `Phone`, `EMail`, `Passwd`) VALUES
(1, 'testing', 'TestClient1', 'TestClientsSurname1', 129, '0.00', NULL, NULL, 'super duper password');

--
-- Triggers `client`
--
DROP TRIGGER IF EXISTS `client_account_delete__request`;
DELIMITER $$
CREATE TRIGGER `client_account_delete__request` AFTER DELETE ON `client` FOR EACH ROW BEGIN 
SET @NoActionDeleteRequestTrigger=1;
DELETE FROM request WHERE Client_Id = OLD.Id;
SET @NoActionDeleteRequestTrigger=0;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `clients`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `clients`;
CREATE TABLE `clients` (
`Id` int(11)
,`Username` varchar(20)
,`Name` varchar(255)
,`Surname` varchar(255)
,`Country` varchar(255)
,`Balance` varchar(27)
,`Phone` varchar(255)
,`EMail` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `clients_raw`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `clients_raw`;
CREATE TABLE `clients_raw` (
`Id` int(11)
,`Username` varchar(20)
,`Name` varchar(255)
,`Surname` varchar(255)
,`Country` varchar(255)
,`Balance` decimal(24,2)
,`Phone` varchar(255)
,`EMail` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `country`
--

DROP TABLE IF EXISTS `country`;
CREATE TABLE `country` (
  `Id` int(11) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `International_fee` decimal(24,2) NOT NULL DEFAULT 0.00,
  `Internal_fee` decimal(24,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `country`
--

INSERT INTO `country` (`Id`, `Name`, `International_fee`, `Internal_fee`) VALUES
(1, 'Afghanistan', '3.68', '0.52'),
(2, 'Albania', '4.54', '0.20'),
(3, 'Algeria', '4.57', '1.63'),
(4, 'Andorra', '1.71', '0.94'),
(5, 'Angola', '2.37', '1.04'),
(6, 'Antigua and Barbuda', '2.45', '1.84'),
(7, 'Argentina', '1.73', '0.82'),
(8, 'Armenia', '2.27', '0.88'),
(9, 'Australia', '4.36', '1.48'),
(10, 'Austria', '3.35', '0.95'),
(11, 'Azerbaijan', '0.55', '0.20'),
(12, 'The Bahamas', '2.11', '0.24'),
(13, 'Bahrain', '3.44', '1.91'),
(14, 'Bangladesh', '3.95', '1.63'),
(15, 'Barbados', '0.49', '0.80'),
(16, 'Belarus', '0.75', '1.47'),
(17, 'Belgium', '4.54', '1.47'),
(18, 'Belize', '2.26', '1.71'),
(19, 'Benin', '0.17', '1.72'),
(20, 'Bhutan', '1.23', '1.73'),
(21, 'Bolivia', '3.69', '1.47'),
(22, 'Bosnia and Herzegovina', '4.03', '1.22'),
(23, 'Botswana', '2.73', '1.33'),
(24, 'Brazil', '0.32', '0.10'),
(25, 'Brunei', '1.27', '0.35'),
(26, 'Bulgaria', '2.08', '0.71'),
(27, 'Burkina Faso', '2.69', '1.27'),
(28, 'Burundi', '1.63', '0.26'),
(29, 'Cabo Verde', '1.05', '1.33'),
(30, 'Cambodia', '3.58', '0.34'),
(31, 'Cameroon', '2.57', '1.58'),
(32, 'Canada', '0.89', '0.40'),
(33, 'Central African Republic', '2.02', '1.66'),
(34, 'Chad', '4.22', '1.29'),
(35, 'Chile', '2.78', '1.72'),
(36, 'China', '1.47', '1.63'),
(37, 'Colombia', '2.77', '1.06'),
(38, 'Comoros', '4.71', '0.49'),
(39, 'Democratic Republic of the Congo ', '0.81', '1.88'),
(40, 'Republic of the Congo', '1.77', '0.85'),
(41, 'Costa Rica', '2.28', '0.81'),
(42, 'Côte d’Ivoire', '1.21', '1.39'),
(43, 'Croatia', '4.82', '2.00'),
(44, 'Cuba', '3.86', '1.74'),
(45, 'Cyprus', '0.04', '0.18'),
(46, 'Czech Republic', '0.21', '1.29'),
(47, 'Denmark', '4.16', '1.41'),
(48, 'Djibouti', '4.18', '0.33'),
(49, 'Dominica', '2.87', '0.66'),
(50, 'Dominican Republic', '2.93', '1.40'),
(51, 'East Timor (Timor-Leste)', '0.86', '1.57'),
(52, 'Ecuador', '2.46', '1.82'),
(53, 'Egypt', '3.06', '0.85'),
(54, 'El Salvador', '3.67', '0.93'),
(55, 'Equatorial Guinea', '1.86', '0.37'),
(56, 'Eritrea', '2.45', '1.43'),
(57, 'Estonia', '1.57', '1.25'),
(58, 'Eswatini', '3.73', '1.75'),
(59, 'Ethiopia', '3.64', '0.40'),
(60, 'Fiji', '0.48', '0.41'),
(61, 'Finland', '1.67', '1.72'),
(62, 'France', '4.36', '0.05'),
(63, 'Gabon', '0.10', '0.42'),
(64, 'The Gambia', '0.48', '0.05'),
(65, 'Georgia', '0.68', '1.71'),
(66, 'Germany', '2.85', '0.65'),
(67, 'Ghana', '3.81', '0.93'),
(68, 'Greece', '0.69', '1.42'),
(69, 'Grenada', '4.26', '0.64'),
(70, 'Guatemala', '3.72', '0.61'),
(71, 'Guinea', '3.32', '0.28'),
(72, 'Guinea-Bissau', '4.97', '1.49'),
(73, 'Guyana', '2.43', '1.19'),
(74, 'Haiti', '4.35', '0.64'),
(75, 'Honduras', '4.92', '1.05'),
(76, 'Hungary', '3.89', '0.25'),
(77, 'Iceland', '1.37', '0.56'),
(78, 'India', '3.47', '1.06'),
(79, 'Indonesia', '3.36', '1.04'),
(80, 'Iran', '2.05', '1.44'),
(81, 'Iraq', '3.61', '0.87'),
(82, 'Ireland', '4.48', '1.99'),
(83, 'Israel', '2.54', '0.00'),
(84, 'Italy', '1.49', '1.49'),
(85, 'Jamaica', '0.92', '1.13'),
(86, 'Japan', '3.98', '0.61'),
(87, 'Jordan', '4.12', '0.87'),
(88, 'Kazakhstan', '2.40', '1.72'),
(89, 'Kenya', '1.76', '0.23'),
(90, 'Kiribati', '1.07', '1.42'),
(91, 'South Korea', '4.52', '1.44'),
(92, 'Kosovo', '4.38', '1.82'),
(93, 'Kuwait', '2.57', '1.67'),
(94, 'Kyrgyzstan', '4.32', '1.88'),
(95, 'Laos', '4.43', '0.02'),
(96, 'Latvia', '2.94', '0.25'),
(97, 'Lebanon', '0.48', '0.79'),
(98, 'Lesotho', '2.30', '0.18'),
(99, 'Liberia', '2.06', '0.45'),
(100, 'Libya', '3.42', '1.16'),
(101, 'Liechtenstein', '4.48', '0.58'),
(102, 'Lithuania', '1.14', '2.00'),
(103, 'Luxembourg', '3.59', '0.94'),
(104, 'Madagascar', '1.33', '1.61'),
(105, 'Malawi', '1.12', '0.18'),
(106, 'Malaysia', '0.92', '1.91'),
(107, 'Maldives', '2.84', '1.49'),
(108, 'Mali', '0.91', '0.61'),
(109, 'Malta', '3.82', '1.08'),
(110, 'Marshall Islands', '4.38', '0.08'),
(111, 'Mauritania', '3.52', '1.93'),
(112, 'Mauritius', '4.25', '1.22'),
(113, 'Mexico', '2.50', '0.19'),
(114, 'Micronesia', '0.10', '1.95'),
(115, 'Moldova', '4.38', '1.51'),
(116, 'Monaco', '1.62', '0.94'),
(117, 'Mongolia', '1.61', '0.47'),
(118, 'Montenegro', '2.63', '0.25'),
(119, 'Morocco', '4.91', '0.93'),
(120, 'Mozambique', '4.82', '0.96'),
(121, 'Myanmar (Burma)', '2.84', '0.73'),
(122, 'Namibia', '1.99', '0.47'),
(123, 'Nauru', '4.40', '0.19'),
(124, 'Nepal', '1.82', '0.16'),
(125, 'Netherlands', '1.33', '0.45'),
(126, 'New Zealand', '1.58', '1.35'),
(127, 'Nicaragua', '3.33', '0.69'),
(128, 'Niger', '3.32', '0.25'),
(129, 'Nigeria', '1.20', '0.90'),
(130, 'North Macedonia', '2.08', '0.89'),
(131, 'Norway', '4.41', '1.92'),
(132, 'Oman', '4.49', '0.53'),
(133, 'Pakistan', '3.07', '0.38'),
(134, 'Palau', '2.01', '1.86'),
(135, 'Panama', '0.84', '0.52'),
(136, 'Papua New Guinea', '3.03', '1.73'),
(137, 'Paraguay', '1.38', '1.08'),
(138, 'Peru', '2.65', '0.37'),
(139, 'Philippines', '3.33', '0.29'),
(140, 'Poland', '1.26', '1.70'),
(141, 'Portugal', '1.05', '0.52'),
(142, 'Qatar', '1.36', '0.26'),
(143, 'Romania', '2.35', '0.95'),
(144, 'Russia', '1.20', '1.99'),
(145, 'Rwanda', '1.63', '0.37'),
(146, 'Saint Kitts and Nevis', '1.30', '1.06'),
(147, 'Saint Lucia', '2.38', '0.54'),
(148, 'Saint Vincent and the Grenadines', '3.77', '0.54'),
(149, 'Samoa', '0.41', '0.11'),
(150, 'San Marino', '1.82', '1.53'),
(151, 'Sao Tome and Principe', '0.85', '1.92'),
(152, 'Saudi Arabia', '1.88', '1.60'),
(153, 'Senegal', '2.47', '1.06'),
(154, 'Serbia', '3.31', '1.80'),
(155, 'Seychelles', '1.19', '0.88'),
(156, 'Sierra Leone', '2.08', '0.73'),
(157, 'Singapore', '3.12', '1.13'),
(158, 'Slovakia', '3.59', '1.38'),
(159, 'Slovenia', '4.81', '1.95'),
(160, 'Solomon Islands', '4.78', '1.06'),
(161, 'Somalia', '4.30', '1.94'),
(162, 'South Africa', '3.30', '0.03'),
(163, 'Spain', '0.96', '1.50'),
(164, 'Sri Lanka', '2.07', '1.61'),
(165, 'Sudan', '0.23', '0.20'),
(166, 'South Sudan', '0.74', '0.53'),
(167, 'Suriname', '2.13', '1.53'),
(168, 'Sweden', '0.25', '0.72'),
(169, 'Switzerland', '3.44', '1.94'),
(170, 'Syria', '0.43', '0.36'),
(171, 'Taiwan', '2.66', '0.96'),
(172, 'Tajikistan', '4.81', '0.28'),
(173, 'Tanzania', '1.97', '1.59'),
(174, 'Thailand', '2.33', '1.12'),
(175, 'Togo', '4.23', '1.75'),
(176, 'Tonga', '1.62', '1.60'),
(177, 'Trinidad and Tobago', '1.30', '0.09'),
(178, 'Tunisia', '0.45', '1.45'),
(179, 'Turkey', '2.22', '0.29'),
(180, 'Turkmenistan', '4.46', '0.50'),
(181, 'Tuvalu', '1.95', '0.62'),
(182, 'Uganda', '3.10', '1.71'),
(183, 'Ukraine', '1.78', '0.77'),
(184, 'United Arab Emirates', '3.16', '0.43'),
(185, 'United Kingdom', '4.85', '1.47'),
(186, 'United States', '1.71', '1.23'),
(187, 'Uruguay', '1.37', '0.80'),
(188, 'Uzbekistan', '4.01', '1.98'),
(189, 'Vanuatu', '3.59', '1.39'),
(190, 'Vatican City', '2.41', '1.86'),
(191, 'Venezuela', '3.34', '0.64'),
(192, 'Vietnam', '3.44', '1.56'),
(193, 'Yemen', '3.47', '1.33'),
(194, 'Zambia', '4.24', '0.20'),
(195, 'Zimbabwe', '3.30', '0.39');

-- --------------------------------------------------------

--
-- Table structure for table `item`
--

DROP TABLE IF EXISTS `item`;
CREATE TABLE `item` (
  `Id` bigint(20) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Description` text NOT NULL DEFAULT '',
  `Owner` int(11) NOT NULL,
  `Price` decimal(24,2) NOT NULL DEFAULT 0.00,
  `Amount_In_Stock` int(11) NOT NULL DEFAULT 0
) ;

--
-- Dumping data for table `item`
--

INSERT INTO `item` (`Id`, `Name`, `Description`, `Owner`, `Price`, `Amount_In_Stock`) VALUES
(1, 'Air Bag', 'Bag Full Of Air', 1, '10.50', 5),
(2, 'Water Bag', '', 1, '100.30', 9),
(3, 'Water Bag', '', 1, '100.30', 14);

--
-- Triggers `item`
--
DROP TRIGGER IF EXISTS `item_deletion_delete_in_request`;
DELIMITER $$
CREATE TRIGGER `item_deletion_delete_in_request` AFTER DELETE ON `item` FOR EACH ROW BEGIN
        DELETE FROM shipment WHERE Item_Id = OLD.Id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `request`
--

DROP TABLE IF EXISTS `request`;
CREATE TABLE `request` (
  `Id` bigint(20) NOT NULL,
  `Seller_Id` int(11) NOT NULL,
  `Client_Id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `request`
--

INSERT INTO `request` (`Id`, `Seller_Id`, `Client_Id`) VALUES
(21, 1, 1);

--
-- Triggers `request`
--
DROP TRIGGER IF EXISTS `request_delete`;
DELIMITER $$
CREATE TRIGGER `request_delete` BEFORE DELETE ON `request` FOR EACH ROW BEGIN
    IF @NoActionDeleteRequestTrigger is NULL OR @NoActionDeleteRequestTrigger <> 1 THEN
    IF NOT check_request_correctness(OLD.Id, OLD.Seller_Id) THEN
        SIGNAL SQLSTATE '45000';
    END IF;
    IF (SELECT COUNT(Request_Id) FROM shipment WHERE Request_Id = OLD.Id) = 0 THEN
        SIGNAL SQLSTATE '45000';
    END IF;
    SET @total=IFNULL((
                          SELECT SUM(Price * Amount) FROM item
                                                              INNER JOIN shipment s on item.Id = s.Item_Id
                          WHERE s.Request_Id = OLD.Id
                      ), 0);
    SET @client_country=(SELECT Country FROM client WHERE client.Id = OLD.Client_Id);
    SET @seller_country=(SELECT Country FROM seller WHERE seller.Id = OLD.Seller_Id);
    SET @fee = 0.0;
    IF @client_country = @seller_country THEN
        SET @fee = (SELECT Internal_fee FROM country WHERE country.Id = @seller_country);
    ELSE
        SET @fee = (SELECT International_fee FROM country WHERE country.Id = @seller_country);
    END IF;

    UPDATE seller SET seller.Balance = seller.Balance + @total WHERE Id = OLD.Seller_Id;
    SET @total = @total + @fee;
    UPDATE client SET client.Balance = client.Balance - @total WHERE Id = OLD.Client_Id;
    
        INSERT INTO request_arch(Seller_Id, Client_Id, Total, Date, Date_Mod)
        VALUES(OLD.Seller_Id, OLD.Client_Id, @total, current_timestamp, current_timestamp);
    
    UPDATE item SET Amount_In_Stock = Amount_In_Stock -
                                      IFNULL((SELECT Amount FROM shipment WHERE Item_Id = item.Id AND Request_Id = OLD.Id), 0);
    DELETE FROM shipment WHERE Request_Id = OLD.Id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `requests`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `requests`;
CREATE TABLE `requests` (
`Id` bigint(20)
,`Clients Name(Username)` text
,`Sellers Name(Username)` text
,`Total Price` decimal(56,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `request_arch`
--

DROP TABLE IF EXISTS `request_arch`;
CREATE TABLE `request_arch` (
  `Id` bigint(20) NOT NULL,
  `Seller_Id` int(11) NOT NULL,
  `Client_Id` int(11) NOT NULL,
  `Total` decimal(24,2) NOT NULL,
  `Date` datetime NOT NULL DEFAULT current_timestamp(),
  `Date_Mod` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `request_arch`
--

INSERT INTO `request_arch` (`Id`, `Seller_Id`, `Client_Id`, `Total`, `Date`, `Date_Mod`) VALUES
(1, 0, 0, '0.00', '0000-00-00 00:00:00', '2021-12-08 00:00:00');

--
-- Triggers `request_arch`
--
DROP TRIGGER IF EXISTS `request_arch_modify`;
DELIMITER $$
CREATE TRIGGER `request_arch_modify` BEFORE UPDATE ON `request_arch` FOR EACH ROW BEGIN
    SET NEW.Date_Mod = current_timestamp;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `seller`
--

DROP TABLE IF EXISTS `seller`;
CREATE TABLE `seller` (
  `Id` int(11) NOT NULL,
  `Username` varchar(20) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Surname` varchar(255) NOT NULL,
  `Country` int(11) NOT NULL,
  `Balance` decimal(24,2) NOT NULL DEFAULT 0.00,
  `Phone` varchar(255) DEFAULT NULL,
  `Email` varchar(255) DEFAULT NULL,
  `Passwd` varchar(255) NOT NULL
) ;

--
-- Dumping data for table `seller`
--

INSERT INTO `seller` (`Id`, `Username`, `Name`, `Surname`, `Country`, `Balance`, `Phone`, `Email`, `Passwd`) VALUES
(1, 'test', 'TestName1', 'TestSurname1', 1, '599.00', '734895834', 'test@localhost.en', 'test');

--
-- Triggers `seller`
--
DROP TRIGGER IF EXISTS `seller_account_delete__items`;
DELIMITER $$
CREATE TRIGGER `seller_account_delete__items` AFTER DELETE ON `seller` FOR EACH ROW BEGIN
        DELETE FROM item WHERE Owner = OLD.Id;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `seller_account_delete__request`;
DELIMITER $$
CREATE TRIGGER `seller_account_delete__request` AFTER DELETE ON `seller` FOR EACH ROW BEGIN 
SET @NoActionDeleteRequestTrigger=1;
DELETE FROM request WHERE request.Seller_Id = OLD.Id;
SET @NoActionDeleteRequestTrigger=0;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `sellers`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `sellers`;
CREATE TABLE `sellers` (
`Id` int(11)
,`Username` varchar(20)
,`Name` varchar(255)
,`Surname` varchar(255)
,`Country` varchar(255)
,`Balance` varchar(27)
,`Phone` varchar(255)
,`EMail` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `sellers_raw`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `sellers_raw`;
CREATE TABLE `sellers_raw` (
`Id` int(11)
,`Username` varchar(20)
,`Name` varchar(255)
,`Surname` varchar(255)
,`Country` varchar(255)
,`Balance` decimal(24,2)
,`Phone` varchar(255)
,`EMail` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `shipment`
--

DROP TABLE IF EXISTS `shipment`;
CREATE TABLE `shipment` (
  `Item_Id` bigint(20) NOT NULL,
  `Request_Id` bigint(20) NOT NULL,
  `Amount` int(11) NOT NULL
) ;

--
-- Dumping data for table `shipment`
--

INSERT INTO `shipment` (`Item_Id`, `Request_Id`, `Amount`) VALUES
(1, 21, 4);

--
-- Triggers `shipment`
--
DROP TRIGGER IF EXISTS `shipment_delete__empty_request`;
DELIMITER $$
CREATE TRIGGER `shipment_delete__empty_request` AFTER DELETE ON `shipment` FOR EACH ROW BEGIN
    IF NOT EXISTS((SELECT * FROM shipment WHERE Request_Id = OLD.Request_Id)) THEN
        SET @NoActionDeleteRequestTrigger=1;
        DELETE FROM request WHERE Id = OLD.Request_Id;
        SET @NoActionDeleteRequestTrigger=0;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `transactions`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `transactions`;
CREATE TABLE `transactions` (
`Clients Name(Username)` text
,`Sellers Name(Username)` text
,`Item Name` varchar(255)
,`Amount` int(11)
,`Total Price` varchar(37)
);

-- --------------------------------------------------------

--
-- Structure for view `clients`
--
DROP TABLE IF EXISTS `clients`;

DROP VIEW IF EXISTS `clients`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `clients`  AS SELECT `clients_raw`.`Id` AS `Id`, `clients_raw`.`Username` AS `Username`, `clients_raw`.`Name` AS `Name`, `clients_raw`.`Surname` AS `Surname`, `clients_raw`.`Country` AS `Country`, concat('$',`clients_raw`.`Balance`) AS `Balance`, `clients_raw`.`Phone` AS `Phone`, `clients_raw`.`EMail` AS `EMail` FROM `clients_raw` ;

-- --------------------------------------------------------

--
-- Structure for view `clients_raw`
--
DROP TABLE IF EXISTS `clients_raw`;

DROP VIEW IF EXISTS `clients_raw`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `clients_raw`  AS SELECT `client`.`Id` AS `Id`, `client`.`Username` AS `Username`, `client`.`Name` AS `Name`, `client`.`Surname` AS `Surname`, `country`.`Name` AS `Country`, `client`.`Balance` AS `Balance`, `client`.`Phone` AS `Phone`, `client`.`EMail` AS `EMail` FROM (`client` join `country` on(`client`.`Country` = `country`.`Id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `requests`
--
DROP TABLE IF EXISTS `requests`;

DROP VIEW IF EXISTS `requests`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `requests`  AS SELECT `request`.`Id` AS `Id`, concat(`client`.`Name`,' ',`client`.`Surname`,' (',`client`.`Username`,')') AS `Clients Name(Username)`, concat(`seller`.`Name`,' ',`seller`.`Surname`,' (',`seller`.`Username`,')') AS `Sellers Name(Username)`, sum(`item`.`Price` * `shipment`.`Amount`) AS `Total Price` FROM ((((`request` join `shipment` on(`request`.`Id` = `shipment`.`Request_Id`)) join `client` on(`client`.`Id` = `request`.`Client_Id`)) join `seller` on(`seller`.`Id` = `request`.`Seller_Id`)) join `item` on(`item`.`Id` = `shipment`.`Item_Id`)) GROUP BY `request`.`Id` ;

-- --------------------------------------------------------

--
-- Structure for view `sellers`
--
DROP TABLE IF EXISTS `sellers`;

DROP VIEW IF EXISTS `sellers`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `sellers`  AS SELECT `sellers_raw`.`Id` AS `Id`, `sellers_raw`.`Username` AS `Username`, `sellers_raw`.`Name` AS `Name`, `sellers_raw`.`Surname` AS `Surname`, `sellers_raw`.`Country` AS `Country`, concat('$',`sellers_raw`.`Balance`) AS `Balance`, `sellers_raw`.`Phone` AS `Phone`, `sellers_raw`.`EMail` AS `EMail` FROM `sellers_raw` ;

-- --------------------------------------------------------

--
-- Structure for view `sellers_raw`
--
DROP TABLE IF EXISTS `sellers_raw`;

DROP VIEW IF EXISTS `sellers_raw`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `sellers_raw`  AS SELECT `seller`.`Id` AS `Id`, `seller`.`Username` AS `Username`, `seller`.`Name` AS `Name`, `seller`.`Surname` AS `Surname`, `country`.`Name` AS `Country`, `seller`.`Balance` AS `Balance`, `seller`.`Phone` AS `Phone`, `seller`.`Email` AS `EMail` FROM (`seller` join `country` on(`seller`.`Country` = `country`.`Id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `transactions`
--
DROP TABLE IF EXISTS `transactions`;

DROP VIEW IF EXISTS `transactions`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `transactions`  AS SELECT concat(`client`.`Name`,' ',`client`.`Surname`,' (',`client`.`Username`,')') AS `Clients Name(Username)`, concat(`seller`.`Name`,' ',`seller`.`Surname`,' (',`seller`.`Username`,')') AS `Sellers Name(Username)`, `item`.`Name` AS `Item Name`, `shipment`.`Amount` AS `Amount`, concat('$',`item`.`Price` * `shipment`.`Amount`) AS `Total Price` FROM ((((`shipment` join `item` on(`item`.`Id` = `shipment`.`Item_Id`)) join `request` on(`request`.`Id` = `shipment`.`Request_Id`)) join `client` on(`request`.`Client_Id` = `client`.`Id`)) join `seller` on(`item`.`Owner` = `seller`.`Id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `client`
--
ALTER TABLE `client`
  ADD PRIMARY KEY (`Id`),
  ADD UNIQUE KEY `client_username` (`Username`),
  ADD KEY `Country` (`Country`);

--
-- Indexes for table `country`
--
ALTER TABLE `country`
  ADD PRIMARY KEY (`Id`);

--
-- Indexes for table `item`
--
ALTER TABLE `item`
  ADD PRIMARY KEY (`Id`,`Owner`),
  ADD KEY `Owner` (`Owner`);

--
-- Indexes for table `request`
--
ALTER TABLE `request`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `Seller_Id` (`Seller_Id`),
  ADD KEY `Client_Id` (`Client_Id`);

--
-- Indexes for table `request_arch`
--
ALTER TABLE `request_arch`
  ADD PRIMARY KEY (`Id`);

--
-- Indexes for table `seller`
--
ALTER TABLE `seller`
  ADD PRIMARY KEY (`Id`),
  ADD UNIQUE KEY `seller_username` (`Username`),
  ADD KEY `Country` (`Country`);

--
-- Indexes for table `shipment`
--
ALTER TABLE `shipment`
  ADD PRIMARY KEY (`Item_Id`,`Request_Id`),
  ADD KEY `shipment_ibfk_2` (`Request_Id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `client`
--
ALTER TABLE `client`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `country`
--
ALTER TABLE `country`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=196;

--
-- AUTO_INCREMENT for table `item`
--
ALTER TABLE `item`
  MODIFY `Id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `request`
--
ALTER TABLE `request`
  MODIFY `Id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `request_arch`
--
ALTER TABLE `request_arch`
  MODIFY `Id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `seller`
--
ALTER TABLE `seller`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `client`
--
ALTER TABLE `client`
  ADD CONSTRAINT `client_ibfk_1` FOREIGN KEY (`Country`) REFERENCES `country` (`Id`);

--
-- Constraints for table `item`
--
ALTER TABLE `item`
  ADD CONSTRAINT `item_ibfk_1` FOREIGN KEY (`Owner`) REFERENCES `seller` (`Id`);

--
-- Constraints for table `request`
--
ALTER TABLE `request`
  ADD CONSTRAINT `request_ibfk_1` FOREIGN KEY (`Client_Id`) REFERENCES `client` (`Id`) ON DELETE NO ACTION,
  ADD CONSTRAINT `request_ibfk_2` FOREIGN KEY (`Seller_Id`) REFERENCES `seller` (`Id`) ON DELETE NO ACTION;

--
-- Constraints for table `seller`
--
ALTER TABLE `seller`
  ADD CONSTRAINT `seller_ibfk_1` FOREIGN KEY (`Country`) REFERENCES `country` (`Id`);

--
-- Constraints for table `shipment`
--
ALTER TABLE `shipment`
  ADD CONSTRAINT `shipment_ibfk_1` FOREIGN KEY (`Item_Id`) REFERENCES `item` (`Id`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `shipment_ibfk_2` FOREIGN KEY (`Request_Id`) REFERENCES `request` (`Id`) ON DELETE NO ACTION ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
