-- phpMyAdmin SQL Dump
-- version 5.0.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 10, 2021 at 10:24 AM
-- Server version: 10.4.14-MariaDB
-- PHP Version: 7.4.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sklep_internetowy`
--

-- --------------------------------------------------------

--
-- Table structure for table `client`
--

CREATE TABLE `client` (
  `Id` int(11) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Surname` varchar(255) NOT NULL,
  `Continent` int(11) DEFAULT NULL,
  `Phone` varchar(255) DEFAULT NULL,
  `EMail` varchar(255) DEFAULT NULL,
  `Passwd` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `continent`
--

CREATE TABLE `continent` (
  `Id` int(11) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Import_Price` double NOT NULL DEFAULT 0,
  `Export_Price` double NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `item`
--

CREATE TABLE `item` (
  `Id` bigint(20) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Description` text DEFAULT NULL,
  `Owner` int(11) NOT NULL,
  `Price` double NOT NULL DEFAULT 0,
  `Amount_Is_Stock` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `request`
--

CREATE TABLE `request` (
  `Id` bigint(20) NOT NULL,
  `Seller_Id` int(11) NOT NULL,
  `Client_Id` int(11) NOT NULL,
  `Date` date NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Triggers `request`
--
DELIMITER $$
CREATE TRIGGER `DeleteRequest` BEFORE DELETE ON `request` FOR EACH ROW BEGIN
INSERT INTO request_arch
VALUES (NULL, OLD.Seller_Id, OLD.Client_Id,
IFNULL(
 (
	SELECT (
         SUM(shipment.Amount *
    		(SELECT item.Price FROM item WHERE item.Id = shipment.Item_Id LIMIT 1)
         )
     )
	FROM shipment
 	WHERE OLD.Id = shipment.Request_Id
), 0),
Old.Date, Now());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `request_arch`
--

CREATE TABLE `request_arch` (
  `Id` bigint(20) NOT NULL,
  `Seller_Id` int(11) NOT NULL,
  `Client_Id` int(11) NOT NULL,
  `Total` double NOT NULL,
  `Date` date NOT NULL DEFAULT current_timestamp(),
  `Date_Mod` date NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `request_arch`
--

INSERT INTO `request_arch` (`Id`, `Seller_Id`, `Client_Id`, `Total`, `Date`, `Date_Mod`) VALUES
(1, 0, 0, 0, '0000-00-00', '2021-12-08');

-- --------------------------------------------------------

--
-- Table structure for table `seller`
--

CREATE TABLE `seller` (
  `Id` int(11) NOT NULL,
  `Name` varchar(255) NOT NULL,
  `Surname` varchar(255) NOT NULL,
  `Continent` int(11) NOT NULL,
  `Phone` varchar(255) NOT NULL,
  `Email` varchar(255) NOT NULL,
  `Passwd` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `shipment`
--

CREATE TABLE `shipment` (
  `Item_Id` bigint(20) NOT NULL,
  `Request_Id` bigint(20) NOT NULL,
  `Amount` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `client`
--
ALTER TABLE `client`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `client` (`Continent`);

--
-- Indexes for table `continent`
--
ALTER TABLE `continent`
  ADD PRIMARY KEY (`Id`);

--
-- Indexes for table `item`
--
ALTER TABLE `item`
  ADD PRIMARY KEY (`Id`,`Owner`),
  ADD KEY `item_owner` (`Owner`);

--
-- Indexes for table `request`
--
ALTER TABLE `request`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `request` (`Seller_Id`),
  ADD KEY `client_requst` (`Client_Id`);

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
  ADD KEY `seller` (`Continent`);

--
-- Indexes for table `shipment`
--
ALTER TABLE `shipment`
  ADD PRIMARY KEY (`Item_Id`,`Request_Id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `client`
--
ALTER TABLE `client`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `item`
--
ALTER TABLE `item`
  MODIFY `Id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `request`
--
ALTER TABLE `request`
  MODIFY `Id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
  ADD CONSTRAINT `client` FOREIGN KEY (`Continent`) REFERENCES `continent` (`Id`);

--
-- Constraints for table `item`
--
ALTER TABLE `item`
  ADD CONSTRAINT `item_owner` FOREIGN KEY (`Owner`) REFERENCES `seller` (`Id`);

--
-- Constraints for table `request`
--
ALTER TABLE `request`
  ADD CONSTRAINT `client_requst` FOREIGN KEY (`Client_Id`) REFERENCES `client` (`Id`),
  ADD CONSTRAINT `request` FOREIGN KEY (`Seller_Id`) REFERENCES `seller` (`Id`);

--
-- Constraints for table `seller`
--
ALTER TABLE `seller`
  ADD CONSTRAINT `seller` FOREIGN KEY (`Continent`) REFERENCES `continent` (`Id`);

--
-- Constraints for table `shipment`
--
ALTER TABLE `shipment`
  ADD CONSTRAINT `shipment_item` FOREIGN KEY (`Item_Id`) REFERENCES `item` (`Id`),
  ADD CONSTRAINT `shipment_request` FOREIGN KEY (`Item_Id`) REFERENCES `request` (`Id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
