CREATE TABLE IF NOT EXISTS `renzu_projectcars` (
  `plate` varchar(64) NOT NULL DEFAULT '',
  `identifier` varchar(64) NOT NULL DEFAULT '',
  `paint` varchar(128) NULL,
  `coord` varchar(255) NULL,
  `model` varchar(64) NULL,
  `status` longtext NULL,
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `renzu_projectcars_items` (
  `identifier` varchar(64) NOT NULL DEFAULT '',
  `items` longtext NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `owned_vehicles` (
	`owner` VARCHAR(64) NOT NULL COLLATE 'utf8mb4_bin',
	`plate` VARCHAR(12) NOT NULL COLLATE 'utf8mb4_bin',
	`vehicle` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb4_bin',
	`impound` INT(1) NOT NULL DEFAULT '0',
	`stored` INT(1) NOT NULL DEFAULT '0',
	`garage_type` VARCHAR(50) NULL DEFAULT 'car' COLLATE 'utf8mb4_bin',
	`garage_id` VARCHAR(50) NULL DEFAULT 'A' COLLATE 'utf8mb4_bin',
	PRIMARY KEY (`plate`) USING BTREE,
	INDEX `vehsowned` (`owner`) USING BTREE
)
COLLATE='utf8mb4_bin'
ENGINE=InnoDB
;

ALTER TABLE owned_vehicles
ADD `garage_id` varchar(32) NOT NULL DEFAULT 'A';


ALTER TABLE owned_vehicles
ADD job varchar(32) NOT NULL DEFAULT 'civ';

ALTER TABLE owned_vehicles
ADD `stored` varchar(32) NOT NULL DEFAULT 1;