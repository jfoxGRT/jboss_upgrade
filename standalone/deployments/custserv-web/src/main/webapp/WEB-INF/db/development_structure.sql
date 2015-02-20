CREATE TABLE `address_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `agent` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `sam_server_id` int(11) NOT NULL,
  `cookie` varchar(36) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_agent_on_cookie` (`cookie`),
  KEY `sam_server_id` (`sam_server_id`),
  CONSTRAINT `agent_ibfk_1` FOREIGN KEY (`sam_server_id`) REFERENCES `sam_server` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `agent_context` (
  `id` int(11) NOT NULL auto_increment,
  `agent_id` int(11) default NULL,
  `jre_version` int(11) default NULL,
  `microloader_version` int(11) default NULL,
  `sam_install_code` varchar(255) default NULL,
  `next_poll_interval` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`),
  CONSTRAINT `agent_context_ibfk_1` FOREIGN KEY (`agent_id`) REFERENCES `agent` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `agent_context_platform` (
  `id` int(11) NOT NULL auto_increment,
  `agent_context_id` int(11) default NULL,
  `os_series` varchar(255) default NULL,
  `cpu_bits` varchar(255) default NULL,
  `os_family` varchar(255) default NULL,
  `cpu_type` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `agent_context_id` (`agent_context_id`),
  CONSTRAINT `agent_context_platform_ibfk_1` FOREIGN KEY (`agent_context_id`) REFERENCES `agent_context` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `agent_context_plugin` (
  `id` int(11) NOT NULL auto_increment,
  `agent_context_id` int(11) default NULL,
  `value` int(11) default NULL,
  `name` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `agent_context_id` (`agent_context_id`),
  CONSTRAINT `agent_context_plugin_ibfk_1` FOREIGN KEY (`agent_context_id`) REFERENCES `agent_context` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `alert` (
  `id` int(11) NOT NULL auto_increment,
  `alert_target_type_id` int(11) default NULL,
  `alert_message_type_id` int(11) default NULL,
  `alert_source_type_id` int(11) default NULL,
  `alert_subject_type_id` int(11) default NULL,
  `alert_source_id` int(11) default NULL,
  `message_text` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `alert_target_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `alert_target_type_id` (`alert_target_type_id`),
  KEY `alert_message_type_id` (`alert_message_type_id`),
  KEY `alert_source_type_id` (`alert_source_type_id`),
  KEY `alert_subject_type_id` (`alert_subject_type_id`),
  CONSTRAINT `alert_ibfk_4` FOREIGN KEY (`alert_subject_type_id`) REFERENCES `alert_subject_type` (`id`),
  CONSTRAINT `alert_ibfk_1` FOREIGN KEY (`alert_target_type_id`) REFERENCES `alert_target_type` (`id`),
  CONSTRAINT `alert_ibfk_2` FOREIGN KEY (`alert_message_type_id`) REFERENCES `alert_message_type` (`id`),
  CONSTRAINT `alert_ibfk_3` FOREIGN KEY (`alert_source_type_id`) REFERENCES `alert_source_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `alert_message_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `alert_source_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `alert_subject_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `alert_target_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `auth_src_verified` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  `text` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `collection_method` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `indicator` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  `text` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `community` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `short_name` varchar(255) default NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conversation_command` (
  `id` int(11) NOT NULL auto_increment,
  `command_id` varchar(255) NOT NULL,
  `plugin_id` varchar(255) NOT NULL,
  `conversation_state_instance_id` int(11) NOT NULL,
  `success` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `conversation_state_instance_id` (`conversation_state_instance_id`),
  CONSTRAINT `conversation_command_ibfk_1` FOREIGN KEY (`conversation_state_instance_id`) REFERENCES `conversation_state_instance` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conversation_command_error` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `value` varchar(255) default NULL,
  `conversation_command_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `conversation_command_id` (`conversation_command_id`),
  CONSTRAINT `conversation_command_error_ibfk_1` FOREIGN KEY (`conversation_command_id`) REFERENCES `conversation_command` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conversation_command_property` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `value` varchar(255) default NULL,
  `conversation_command_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `conversation_command_id` (`conversation_command_id`),
  CONSTRAINT `conversation_command_property_ibfk_1` FOREIGN KEY (`conversation_command_id`) REFERENCES `conversation_command` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conversation_current_state` (
  `id` int(11) NOT NULL auto_increment,
  `conversation_instance_id` int(11) default NULL,
  `conversation_state_instance_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `conversation_instance_id` (`conversation_instance_id`),
  KEY `conversation_state_instance_id` (`conversation_state_instance_id`),
  CONSTRAINT `conversation_current_state_ibfk_2` FOREIGN KEY (`conversation_state_instance_id`) REFERENCES `conversation_state_instance` (`id`),
  CONSTRAINT `conversation_current_state_ibfk_1` FOREIGN KEY (`conversation_instance_id`) REFERENCES `conversation_instance` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conversation_instance` (
  `id` int(11) NOT NULL auto_increment,
  `adapter_identifier` varchar(255) default NULL,
  `conversation_identifier` varchar(255) default NULL,
  `agent_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `started` datetime default NULL,
  `completed` datetime default NULL,
  `result_type_id` int(11) NOT NULL,
  `result_msg` varchar(2048) default NULL,
  PRIMARY KEY  (`id`),
  KEY `agent_id` (`agent_id`),
  KEY `result_type_id` (`result_type_id`),
  CONSTRAINT `conversation_instance_ibfk_2` FOREIGN KEY (`result_type_id`) REFERENCES `conversation_result_type` (`id`),
  CONSTRAINT `conversation_instance_ibfk_1` FOREIGN KEY (`agent_id`) REFERENCES `agent` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conversation_instance_variable` (
  `id` int(11) NOT NULL auto_increment,
  `conversation_instance_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  `value` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `conversation_instance_id` (`conversation_instance_id`),
  CONSTRAINT `conversation_instance_variable_ibfk_1` FOREIGN KEY (`conversation_instance_id`) REFERENCES `conversation_instance` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conversation_result_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conversation_state_instance` (
  `id` int(11) NOT NULL auto_increment,
  `conversation_instance_id` int(11) default NULL,
  `state_identifier` varchar(255) default NULL,
  `created_at` datetime NOT NULL,
  `entered` datetime default NULL,
  `exited` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `conversation_instance_id` (`conversation_instance_id`),
  CONSTRAINT `conversation_state_instance_ibfk_1` FOREIGN KEY (`conversation_instance_id`) REFERENCES `conversation_instance` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `country` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `iso_code` varchar(255) default NULL,
  `name` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `customer` (
  `id` int(11) NOT NULL auto_increment,
  `ucn` int(11) default NULL,
  `customer_group_id` int(11) default NULL,
  `customer_type_id` int(11) default NULL,
  `customer_status_id` int(11) default NULL,
  `customer_added_date` date default NULL,
  PRIMARY KEY  (`id`),
  KEY `customer_group_id` (`customer_group_id`),
  KEY `customer_type_id` (`customer_type_id`),
  KEY `customer_status_id` (`customer_status_id`),
  CONSTRAINT `customer_ibfk_3` FOREIGN KEY (`customer_status_id`) REFERENCES `customer_status` (`id`),
  CONSTRAINT `customer_ibfk_1` FOREIGN KEY (`customer_group_id`) REFERENCES `customer_group` (`id`),
  CONSTRAINT `customer_ibfk_2` FOREIGN KEY (`customer_type_id`) REFERENCES `customer_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `customer_address` (
  `id` int(11) NOT NULL auto_increment,
  `customer_id` int(11) default NULL,
  `address_type_id` int(11) default NULL,
  `usps_record_type_id` int(11) default NULL,
  `address_line_1` varchar(255) default NULL,
  `address_line_2` varchar(255) default NULL,
  `address_line_3` varchar(255) default NULL,
  `address_line_4` varchar(255) default NULL,
  `address_line_5` varchar(255) default NULL,
  `city_name` varchar(255) default NULL,
  `state_province_id` int(11) default NULL,
  `postal_code` varchar(255) default NULL,
  `county_code` varchar(255) default NULL,
  `country_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `address_type_id` (`address_type_id`),
  KEY `usps_record_type_id` (`usps_record_type_id`),
  KEY `state_province_id` (`state_province_id`),
  KEY `country_id` (`country_id`),
  CONSTRAINT `customer_address_ibfk_5` FOREIGN KEY (`country_id`) REFERENCES `country` (`id`),
  CONSTRAINT `customer_address_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `customer_address_ibfk_2` FOREIGN KEY (`address_type_id`) REFERENCES `address_type` (`id`),
  CONSTRAINT `customer_address_ibfk_3` FOREIGN KEY (`usps_record_type_id`) REFERENCES `usps_record_type` (`id`),
  CONSTRAINT `customer_address_ibfk_4` FOREIGN KEY (`state_province_id`) REFERENCES `state_province` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `customer_group` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `customer_relationship` (
  `id` int(11) NOT NULL auto_increment,
  `customer_id` int(11) default NULL,
  `related_customer_id` int(11) default NULL,
  `relationship_type_id` int(11) default NULL,
  `effective` date default NULL,
  `end` date default NULL,
  `relationship_category_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `related_customer_id` (`related_customer_id`),
  KEY `relationship_type_id` (`relationship_type_id`),
  KEY `relationship_category_id` (`relationship_category_id`),
  CONSTRAINT `customer_relationship_ibfk_4` FOREIGN KEY (`relationship_category_id`) REFERENCES `relationship_category` (`id`),
  CONSTRAINT `customer_relationship_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `customer_relationship_ibfk_2` FOREIGN KEY (`related_customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `customer_relationship_ibfk_3` FOREIGN KEY (`relationship_type_id`) REFERENCES `relationship_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `customer_role` (
  `id` int(11) NOT NULL auto_increment,
  `customer_id` int(11) default NULL,
  `related_customer_id` int(11) default NULL,
  `relationship_type_id` int(11) default NULL,
  `role_group_id` int(11) default NULL,
  `role_type_id` int(11) default NULL,
  `related_role_group_id` int(11) default NULL,
  `related_role_type_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `related_customer_id` (`related_customer_id`),
  KEY `relationship_type_id` (`relationship_type_id`),
  KEY `role_group_id` (`role_group_id`),
  KEY `role_type_id` (`role_type_id`),
  KEY `related_role_group_id` (`related_role_group_id`),
  KEY `related_role_type_id` (`related_role_type_id`),
  CONSTRAINT `customer_role_ibfk_7` FOREIGN KEY (`related_role_type_id`) REFERENCES `role_group` (`id`),
  CONSTRAINT `customer_role_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `customer_role_ibfk_2` FOREIGN KEY (`related_customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `customer_role_ibfk_3` FOREIGN KEY (`relationship_type_id`) REFERENCES `relationship_type` (`id`),
  CONSTRAINT `customer_role_ibfk_4` FOREIGN KEY (`role_group_id`) REFERENCES `role_group` (`id`),
  CONSTRAINT `customer_role_ibfk_5` FOREIGN KEY (`role_type_id`) REFERENCES `role_type` (`id`),
  CONSTRAINT `customer_role_ibfk_6` FOREIGN KEY (`related_role_group_id`) REFERENCES `role_group` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `customer_status` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `customer_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `deliv_status` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `edu_individual_customer` (
  `id` int(11) NOT NULL auto_increment,
  `individual_customer_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `individual_customer_id` (`individual_customer_id`),
  CONSTRAINT `edu_individual_customer_ibfk_1` FOREIGN KEY (`individual_customer_id`) REFERENCES `individual_customer` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `email_address` (
  `id` int(11) NOT NULL auto_increment,
  `source_system_customer_id` int(11) default NULL,
  `email_address_type_id` int(11) default NULL,
  `deliv_status_id` int(11) default NULL,
  `email_address` varchar(255) default NULL,
  `deliv_stats_date` datetime default NULL,
  `collection_method_id` int(11) default NULL,
  `preferred_email_indicator` varchar(255) default NULL,
  `email_opt_in_status` varchar(255) default NULL,
  `email_opt_in_date` datetime default NULL,
  `last_acknowledged_date` datetime default NULL,
  `enterprise_email_indicator` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `source_system_customer_id` (`source_system_customer_id`),
  KEY `email_address_type_id` (`email_address_type_id`),
  KEY `deliv_status_id` (`deliv_status_id`),
  KEY `collection_method_id` (`collection_method_id`),
  CONSTRAINT `email_address_ibfk_4` FOREIGN KEY (`collection_method_id`) REFERENCES `collection_method` (`id`),
  CONSTRAINT `email_address_ibfk_1` FOREIGN KEY (`source_system_customer_id`) REFERENCES `source_system_customer` (`id`),
  CONSTRAINT `email_address_ibfk_2` FOREIGN KEY (`email_address_type_id`) REFERENCES `email_address_type` (`id`),
  CONSTRAINT `email_address_ibfk_3` FOREIGN KEY (`deliv_status_id`) REFERENCES `deliv_status` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `email_address_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  `text` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `entitlement` (
  `id` int(11) NOT NULL auto_increment,
  `po_num` varchar(255) default NULL,
  `license_count` int(11) default NULL,
  `license_portability_id` int(11) default NULL,
  `ordered` datetime default NULL,
  `shipped` datetime default NULL,
  `email_address` varchar(255) default NULL,
  `first_name` varchar(255) default NULL,
  `last_name` varchar(255) default NULL,
  `entitlement_type_id` int(11) default NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  `root_organizational_customer_id` int(11) default NULL,
  `license_duration_id` int(11) NOT NULL,
  `order_num` varchar(255) default NULL,
  `originating_order_num` varchar(255) default NULL,
  `shipment_num` varchar(255) default NULL,
  `invoice_num` varchar(255) default NULL,
  `master_order_num` varchar(255) default NULL,
  `license_count_type_id` int(11) default NULL,
  `item_quantity` int(11) default NULL,
  `contact_ucn` varchar(255) default NULL,
  `subscription_start` datetime default NULL,
  `subscription_end` datetime default NULL,
  `grace_period_id` int(11) default NULL,
  `item_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `license_portability_id` (`license_portability_id`),
  KEY `entitlement_type_id` (`entitlement_type_id`),
  KEY `root_organizational_customer_id` (`root_organizational_customer_id`),
  KEY `license_duration_id` (`license_duration_id`),
  KEY `license_count_type_id` (`license_count_type_id`),
  KEY `grace_period_id` (`grace_period_id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `entitlement_ibfk_8` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`),
  CONSTRAINT `entitlement_ibfk_2` FOREIGN KEY (`license_portability_id`) REFERENCES `license_portability` (`id`),
  CONSTRAINT `entitlement_ibfk_3` FOREIGN KEY (`entitlement_type_id`) REFERENCES `entitlement_type` (`id`),
  CONSTRAINT `entitlement_ibfk_4` FOREIGN KEY (`root_organizational_customer_id`) REFERENCES `organizational_customer` (`id`),
  CONSTRAINT `entitlement_ibfk_5` FOREIGN KEY (`license_duration_id`) REFERENCES `license_duration` (`id`),
  CONSTRAINT `entitlement_ibfk_6` FOREIGN KEY (`license_count_type_id`) REFERENCES `license_count_type` (`id`),
  CONSTRAINT `entitlement_ibfk_7` FOREIGN KEY (`grace_period_id`) REFERENCES `grace_period` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `entitlement_org` (
  `id` int(11) NOT NULL auto_increment,
  `entitlement_id` int(11) NOT NULL,
  `entitlement_org_type_id` int(11) NOT NULL,
  `name` varchar(255) default NULL,
  `ucn` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `entitlement_id` (`entitlement_id`),
  KEY `entitlement_org_type_id` (`entitlement_org_type_id`),
  CONSTRAINT `entitlement_org_ibfk_1` FOREIGN KEY (`entitlement_id`) REFERENCES `entitlement` (`id`),
  CONSTRAINT `entitlement_org_ibfk_2` FOREIGN KEY (`entitlement_org_type_id`) REFERENCES `entitlement_org_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `entitlement_org_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `entitlement_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `esb_message` (
  `id` int(11) NOT NULL auto_increment,
  `correlation_id` varchar(255) default NULL,
  `delivery_mode` int(11) default NULL,
  `message_id` varchar(255) NOT NULL,
  `message_timestamp` varchar(255) default NULL,
  `message_text` text NOT NULL,
  `message_type` varchar(255) default NULL,
  `message_class` varchar(255) default NULL,
  `received` datetime NOT NULL,
  `parsed` datetime default NULL,
  `handled` datetime default NULL,
  `ignored` datetime default NULL,
  `held` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `grace_period` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `individual_customer` (
  `id` int(11) NOT NULL auto_increment,
  `customer_id` int(11) default NULL,
  `last_name` varchar(30) default NULL,
  `first_name` varchar(30) default NULL,
  `middle_name` varchar(30) default NULL,
  `gender_code` varchar(1) default NULL,
  `salutation_id` int(11) default NULL,
  `suffix_id` int(11) default NULL,
  `nickname` varchar(30) default NULL,
  PRIMARY KEY  (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `salutation_id` (`salutation_id`),
  KEY `suffix_id` (`suffix_id`),
  CONSTRAINT `individual_customer_ibfk_3` FOREIGN KEY (`suffix_id`) REFERENCES `suffix` (`id`),
  CONSTRAINT `individual_customer_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `individual_customer_ibfk_2` FOREIGN KEY (`salutation_id`) REFERENCES `salutation` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `item` (
  `id` int(11) NOT NULL auto_increment,
  `item_num` varchar(255) NOT NULL,
  `desc` varchar(255) default NULL,
  `product_id` int(11) NOT NULL,
  `licenses` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `item_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `license_count_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `license_duration` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `license_lifetime` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `license_portability` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `org_educational_customer` (
  `id` int(11) NOT NULL auto_increment,
  `organizational_customer_id` int(11) default NULL,
  `student_count` int(11) default NULL,
  `school_year_start_date` date default NULL,
  `school_year_end_date` date default NULL,
  `lowest_grade_code_primary` varchar(2) default NULL,
  `highest_grade_code_primary` varchar(2) default NULL,
  `lowest_grade_code_secondary` varchar(2) default NULL,
  `highest_grade_code_secondary` varchar(2) default NULL,
  `high_age` int(11) default NULL,
  `low_age` int(11) default NULL,
  `nces_state_code` varchar(2) default NULL,
  `nces_district_code` varchar(5) default NULL,
  `nces_school_code` varchar(5) default NULL,
  `nces_link_indicator` varchar(1) default NULL,
  `book_volume_count` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `organizational_customer_id` (`organizational_customer_id`),
  CONSTRAINT `org_educational_customer_ibfk_1` FOREIGN KEY (`organizational_customer_id`) REFERENCES `organizational_customer` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `organizational_customer` (
  `id` int(11) NOT NULL auto_increment,
  `customer_id` int(11) default NULL,
  `name` varchar(100) default NULL,
  `alt_name` varchar(30) default NULL,
  `url` varchar(75) default NULL,
  `public_private_id` int(11) default NULL,
  `religious_affiliation_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `public_private_id` (`public_private_id`),
  KEY `religious_affiliation_id` (`religious_affiliation_id`),
  CONSTRAINT `organizational_customer_ibfk_3` FOREIGN KEY (`religious_affiliation_id`) REFERENCES `religious_affiliation` (`id`),
  CONSTRAINT `organizational_customer_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `organizational_customer_ibfk_2` FOREIGN KEY (`public_private_id`) REFERENCES `public_private` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `product` (
  `id` int(11) NOT NULL auto_increment,
  `desc` varchar(255) NOT NULL,
  `id_provider` varchar(255) NOT NULL,
  `id_value` varchar(255) NOT NULL,
  `product_group_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `product_group_id` (`product_group_id`),
  CONSTRAINT `product_ibfk_1` FOREIGN KEY (`product_group_id`) REFERENCES `product_group` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `product_group` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `product_version` (
  `id` int(11) NOT NULL auto_increment,
  `product_id` int(11) NOT NULL,
  `code` varchar(255) NOT NULL,
  `desc` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `product_version_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `public_private` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `relationship_category` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  `text` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `relationship_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  `text` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `religious_affiliation` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `response_code` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  `text` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `role_group` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `role_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(4) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `salutation` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_customer_role` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_customer_user` (
  `id` int(11) NOT NULL auto_increment,
  `first_name` varchar(255) default NULL,
  `last_name` varchar(255) default NULL,
  `password` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `individual_customer_id` int(11) default NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `individual_customer_id` (`individual_customer_id`),
  CONSTRAINT `sam_customer_user_ibfk_1` FOREIGN KEY (`individual_customer_id`) REFERENCES `individual_customer` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_customer_user_org_role` (
  `id` int(11) NOT NULL auto_increment,
  `sam_customer_user_id` int(11) default NULL,
  `organizational_customer_id` int(11) default NULL,
  `sam_customer_role_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `sam_customer_user_id` (`sam_customer_user_id`),
  KEY `organizational_customer_id` (`organizational_customer_id`),
  KEY `sam_customer_role_id` (`sam_customer_role_id`),
  CONSTRAINT `sam_customer_user_org_role_ibfk_3` FOREIGN KEY (`sam_customer_role_id`) REFERENCES `sam_customer_role` (`id`),
  CONSTRAINT `sam_customer_user_org_role_ibfk_1` FOREIGN KEY (`sam_customer_user_id`) REFERENCES `sam_customer_user` (`id`),
  CONSTRAINT `sam_customer_user_org_role_ibfk_2` FOREIGN KEY (`organizational_customer_id`) REFERENCES `organizational_customer` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_server` (
  `id` int(11) NOT NULL auto_increment,
  `root_organizational_customer_id` int(11) NOT NULL,
  `license_management_level` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `guid` varchar(36) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_sam_server_on_guid` (`guid`),
  KEY `root_organizational_customer_id` (`root_organizational_customer_id`),
  CONSTRAINT `sam_server_ibfk_1` FOREIGN KEY (`root_organizational_customer_id`) REFERENCES `organizational_customer` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_server_address` (
  `id` int(11) NOT NULL auto_increment,
  `sam_server_id` int(11) default NULL,
  `address_type_id` int(11) default NULL,
  `usps_record_type_id` int(11) default NULL,
  `address_line_1` varchar(255) default NULL,
  `address_line_2` varchar(255) default NULL,
  `address_line_3` varchar(255) default NULL,
  `address_line_4` varchar(255) default NULL,
  `address_line_5` varchar(255) default NULL,
  `city_name` varchar(255) default NULL,
  `state_province_id` int(11) default NULL,
  `postal_code` varchar(255) default NULL,
  `county_code` varchar(255) default NULL,
  `country_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `sam_server_id` (`sam_server_id`),
  KEY `address_type_id` (`address_type_id`),
  KEY `usps_record_type_id` (`usps_record_type_id`),
  KEY `state_province_id` (`state_province_id`),
  KEY `country_id` (`country_id`),
  CONSTRAINT `sam_server_address_ibfk_5` FOREIGN KEY (`country_id`) REFERENCES `country` (`id`),
  CONSTRAINT `sam_server_address_ibfk_1` FOREIGN KEY (`sam_server_id`) REFERENCES `sam_server` (`id`),
  CONSTRAINT `sam_server_address_ibfk_2` FOREIGN KEY (`address_type_id`) REFERENCES `address_type` (`id`),
  CONSTRAINT `sam_server_address_ibfk_3` FOREIGN KEY (`usps_record_type_id`) REFERENCES `usps_record_type` (`id`),
  CONSTRAINT `sam_server_address_ibfk_4` FOREIGN KEY (`state_province_id`) REFERENCES `state_province` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_server_administrator` (
  `id` int(11) NOT NULL auto_increment,
  `sam_server_id` int(11) default NULL,
  `sam_customer_user_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `sam_server_id` (`sam_server_id`),
  KEY `sam_customer_user_id` (`sam_customer_user_id`),
  CONSTRAINT `sam_server_administrator_ibfk_2` FOREIGN KEY (`sam_customer_user_id`) REFERENCES `sam_customer_user` (`id`),
  CONSTRAINT `sam_server_administrator_ibfk_1` FOREIGN KEY (`sam_server_id`) REFERENCES `sam_server` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_server_community` (
  `id` int(11) NOT NULL auto_increment,
  `sam_server_id` int(11) default NULL,
  `community_id` int(11) default NULL,
  `management_level_code` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `sam_server_id` (`sam_server_id`),
  KEY `community_id` (`community_id`),
  CONSTRAINT `sam_server_community_ibfk_2` FOREIGN KEY (`community_id`) REFERENCES `community` (`id`),
  CONSTRAINT `sam_server_community_ibfk_1` FOREIGN KEY (`sam_server_id`) REFERENCES `sam_server` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_server_contact` (
  `id` int(11) NOT NULL auto_increment,
  `sam_server_id` int(11) default NULL,
  `telephone_type_id` int(11) default NULL,
  `phone_num` varchar(255) default NULL,
  `phone_ext_num` varchar(255) default NULL,
  `phone_domestic_ind` varchar(255) default NULL,
  `email_address_type_id` int(11) default NULL,
  `email_address` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `sam_server_id` (`sam_server_id`),
  KEY `telephone_type_id` (`telephone_type_id`),
  KEY `email_address_type_id` (`email_address_type_id`),
  CONSTRAINT `sam_server_contact_ibfk_3` FOREIGN KEY (`email_address_type_id`) REFERENCES `email_address_type` (`id`),
  CONSTRAINT `sam_server_contact_ibfk_1` FOREIGN KEY (`sam_server_id`) REFERENCES `sam_server` (`id`),
  CONSTRAINT `sam_server_contact_ibfk_2` FOREIGN KEY (`telephone_type_id`) REFERENCES `telephone_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sam_server_organization` (
  `id` int(11) NOT NULL auto_increment,
  `sam_server_id` int(11) default NULL,
  `organizational_customer_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `sam_server_id` (`sam_server_id`),
  KEY `organizational_customer_id` (`organizational_customer_id`),
  CONSTRAINT `sam_server_organization_ibfk_2` FOREIGN KEY (`organizational_customer_id`) REFERENCES `organizational_customer` (`id`),
  CONSTRAINT `sam_server_organization_ibfk_1` FOREIGN KEY (`sam_server_id`) REFERENCES `sam_server` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `seat` (
  `id` int(11) NOT NULL auto_increment,
  `entitlement_id` int(11) default NULL,
  `position` int(11) default NULL,
  `active` tinyint(1) default NULL,
  `deactivated` datetime default NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `entitlement_id` (`entitlement_id`),
  CONSTRAINT `seat_ibfk_1` FOREIGN KEY (`entitlement_id`) REFERENCES `entitlement` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `seat_assignment` (
  `id` int(11) NOT NULL auto_increment,
  `seat_id` int(11) default NULL,
  `type` varchar(255) default NULL,
  `organization_customer_id` int(11) default NULL,
  `sam_server_id` int(11) default NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `seat_id` (`seat_id`),
  KEY `organization_customer_id` (`organization_customer_id`),
  KEY `sam_server_id` (`sam_server_id`),
  CONSTRAINT `seat_assignment_ibfk_3` FOREIGN KEY (`sam_server_id`) REFERENCES `sam_server` (`id`),
  CONSTRAINT `seat_assignment_ibfk_1` FOREIGN KEY (`seat_id`) REFERENCES `seat` (`id`),
  CONSTRAINT `seat_assignment_ibfk_2` FOREIGN KEY (`organization_customer_id`) REFERENCES `organizational_customer` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `source_system` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(10) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `source_system_customer` (
  `id` int(11) NOT NULL auto_increment,
  `source_system_id` int(11) default NULL,
  `source_system_customer_id` varchar(255) default NULL,
  `customer_id` int(11) default NULL,
  `related_customer_id` int(11) default NULL,
  `account_status` varchar(255) default NULL,
  `account_create_date` datetime default NULL,
  `account_close_date` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `source_system_id` (`source_system_id`),
  KEY `customer_id` (`customer_id`),
  KEY `related_customer_id` (`related_customer_id`),
  CONSTRAINT `source_system_customer_ibfk_3` FOREIGN KEY (`related_customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `source_system_customer_ibfk_1` FOREIGN KEY (`source_system_id`) REFERENCES `source_system` (`id`),
  CONSTRAINT `source_system_customer_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `state_province` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `country_id` int(11) default NULL,
  `name` varchar(75) default NULL,
  PRIMARY KEY  (`id`),
  KEY `country_id` (`country_id`),
  CONSTRAINT `state_province_ibfk_1` FOREIGN KEY (`country_id`) REFERENCES `country` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `subproduct` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(128) default NULL,
  `sam_subproduct_id` varchar(255) default NULL,
  `sam_subproduct_code` varchar(255) default NULL,
  `community_id` int(11) default NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `community_id` (`community_id`),
  CONSTRAINT `subproduct_ibfk_1` FOREIGN KEY (`community_id`) REFERENCES `community` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `suffix` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `system_user` (
  `id` int(11) NOT NULL auto_increment,
  `firstname` varchar(45) default NULL,
  `lastname` varchar(45) default NULL,
  `email` varchar(256) default NULL,
  `username` varchar(256) default NULL,
  `password` varchar(45) default NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `telephone` (
  `id` int(11) NOT NULL auto_increment,
  `customer_id` int(11) default NULL,
  `telephone_type_id` int(11) default NULL,
  `telephone_number` varchar(255) default NULL,
  `telement_extension_number` int(11) default NULL,
  `effective_date` datetime default NULL,
  `fax_authorization_indicator` varchar(255) default NULL,
  `fax_authorization_last_name` varchar(255) default NULL,
  `fax_authorization_first_name` varchar(255) default NULL,
  `fax_authorization_job_title` varchar(255) default NULL,
  `fax_authorization_date` datetime default NULL,
  `fax_authorization_text` varchar(255) default NULL,
  `domestic_indicator` varchar(255) default NULL,
  `last_contact_date` datetime default NULL,
  `response_code_id` int(11) default NULL,
  `state_dncl_indicator` varchar(255) default NULL,
  `state_dncl_update_date` datetime default NULL,
  `federal_dncl_indicator` varchar(255) default NULL,
  `federal_dncl_update_date` datetime default NULL,
  `collection_method_id` int(11) default NULL,
  `last_acknowledged_date` datetime default NULL,
  `enterprise_telephone_indicator` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `telephone_type_id` (`telephone_type_id`),
  KEY `response_code_id` (`response_code_id`),
  KEY `collection_method_id` (`collection_method_id`),
  CONSTRAINT `telephone_ibfk_4` FOREIGN KEY (`collection_method_id`) REFERENCES `collection_method` (`id`),
  CONSTRAINT `telephone_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `telephone_ibfk_2` FOREIGN KEY (`telephone_type_id`) REFERENCES `telephone_type` (`id`),
  CONSTRAINT `telephone_ibfk_3` FOREIGN KEY (`response_code_id`) REFERENCES `response_code` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `telephone_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `customer_classification_indicator` varchar(255) default NULL,
  `desc` varchar(255) default NULL,
  `text` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `usps_record_type` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(3) default NULL,
  `desc` varchar(75) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO schema_info (version) VALUES (17)