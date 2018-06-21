

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `govproxy`
--

-- --------------------------------------------------------

--
-- Table structure for table `IPPool`
--

CREATE TABLE IF NOT EXISTS `IPPool` (
  `id` int(10) NOT NULL,
  `ip` varchar(20) NOT NULL,
  `status` int(1) NOT NULL,
  `node_ip` varchar(50) NOT NULL,
  `org_uuid` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `lb_conf`
--

CREATE TABLE IF NOT EXISTS `lb_conf` (
  `id` int(11) NOT NULL,
  `lb_ip` varchar(50) NOT NULL,
  `lb_vip` varchar(50) NOT NULL,
  `lb_state` varchar(20) NOT NULL,
  `lb_status` varchar(10) NOT NULL,
  `lb_uuid` varchar(100) NOT NULL,
  `lb_name` varchar(100) NOT NULL,
  `lb_initial_pass` varchar(100) NOT NULL,
  `lb_pass` varchar(100) NOT NULL,
  `created` date NOT NULL,
  `modified` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `nodes`
--

CREATE TABLE IF NOT EXISTS `nodes` (
  `id` int(10) NOT NULL,
  `node_ip` varchar(50) NOT NULL,
  `node_name` varchar(100) NOT NULL,
  `node_dns_name` varchar(100) NOT NULL,
  `status` varchar(20) NOT NULL,
  `created` date NOT NULL,
  `modiefied` date NOT NULL,
  `initial_passwd` varchar(100) NOT NULL,
  `uuid` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `org`
--

CREATE TABLE IF NOT EXISTS `org` (
  `id` int(11) NOT NULL,
  `org_name` varchar(100) NOT NULL,
  `org_alias` varchar(15) NOT NULL,
  `org_net_pool` varchar(100) NOT NULL,
  `org_nat_range` varchar(100) NOT NULL,
  `org_vlan` int(100) NOT NULL,
  `org_gw` varchar(100) NOT NULL,
  `org_status` varchar(20) NOT NULL,
  `org_uuid` varchar(100) NOT NULL,
  `IPPool_state` varchar(20) NOT NULL,
  `org_nat_mask` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `IPPool`
--
ALTER TABLE `IPPool`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ip` (`ip`);

--
-- Indexes for table `lb_conf`
--
ALTER TABLE `lb_conf`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `nodes`
--
ALTER TABLE `nodes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `org`
--
ALTER TABLE `org`
  ADD UNIQUE KEY `id` (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `IPPool`
--
ALTER TABLE `IPPool`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `lb_conf`
--
ALTER TABLE `lb_conf`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `nodes`
--
ALTER TABLE `nodes`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `org`
--
ALTER TABLE `org`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
