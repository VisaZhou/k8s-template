CREATE DATABASE IF NOT EXISTS nacos_config DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE nacos_config;

CREATE TABLE IF NOT EXISTS `config_info` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '配置项的唯一标识',
    `encrypted_data_key` text COLLATE utf8_bin COMMENT '加密配置项的密钥',
    `data_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '配置项的唯一标识 ID，用于标识具体配置',
    `group_id` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '配置分组，多个配置项通过此分组区分',
    `content` longtext COLLATE utf8_bin NOT NULL COMMENT '配置项的内容，通常为 JSON 格式的配置信息',
    `md5` varchar(32) COLLATE utf8_bin DEFAULT NULL COMMENT '配置内容的 MD5 值，用于比对是否发生变更',
    `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '配置项的创建时间',
    `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '配置项的最后修改时间',
    `src_user` text COLLATE utf8_bin COMMENT '配置项的来源用户，用于记录修改配置的用户',
    `src_ip` varchar(50) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项的来源 IP，记录用户修改配置时的 IP 地址',
    `app_name` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项所属的应用名称',
    `tenant_id` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户标识，支持多租户模式，可为空字符串表示公共配置',
    `c_desc` varchar(256) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项的描述，提供对配置项的详细解释',
    `c_use` varchar(64) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项的使用场景说明',
    `effect` varchar(64) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项的生效状态，如是否生效或灰度发布等',
    `type` varchar(64) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项类型，例如数据库、缓存等',
    `c_schema` text COLLATE utf8_bin COMMENT '配置项的 schema，描述配置项的数据结构',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_configinfo_datagrouptenant` (`data_id`, `group_id`, `tenant_id`) COMMENT '唯一约束，确保同一租户下数据 ID 和组 ID 不重复'
    ) ENGINE=InnoDB AUTO_INCREMENT=46 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='存储配置信息的表';


CREATE TABLE IF NOT EXISTS `config_info_aggr` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '配置项的唯一标识',
    `data_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '配置项的唯一标识 ID，用于标识具体配置',
    `group_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '配置分组，多个配置项通过此分组区分',
    `datum_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '数据项标识，标识单个配置项的版本或特定实例',
    `content` longtext COLLATE utf8_bin NOT NULL COMMENT '配置项的内容，通常为 JSON 格式的配置信息',
    `gmt_modified` datetime NOT NULL COMMENT '配置项的最后修改时间',
    `app_name` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项所属的应用名称',
    `tenant_id` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户标识，支持多租户模式，可为空字符串表示公共配置',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_configinfoaggr_datagrouptenantdatum` (`data_id`, `group_id`, `tenant_id`, `datum_id`) COMMENT '唯一约束，确保同一租户下数据 ID、组 ID、数据项 ID 唯一'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='存储聚合配置信息的表';


CREATE TABLE IF NOT EXISTS `config_info_beta` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '配置项的唯一标识',
    `data_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '配置项的唯一标识 ID，用于标识具体配置',
    `group_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '配置分组，多个配置项通过此分组区分',
    `content` longtext COLLATE utf8_bin NOT NULL COMMENT '配置项的内容，通常为 JSON 格式的配置信息',
    `gmt_modified` datetime NOT NULL COMMENT '配置项的最后修改时间',
    `app_name` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项所属的应用名称',
    `tenant_id` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户标识，支持多租户模式，可为空字符串表示公共配置',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_configinfobeta_datagrouptenant` (`data_id`, `group_id`, `tenant_id`) COMMENT '唯一约束，确保同一租户下数据 ID 和组 ID 不重复'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='存储灰度配置信息的表';


CREATE TABLE IF NOT EXISTS `config_info_gray` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '唯一标识每条灰度发布记录',
    `data_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '配置项的唯一标识 ID，用于标识具体配置',
    `group_id` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT '配置分组，多个配置项通过此分组区分',
    `app_name` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项所属的应用名称',
    `content` longtext COLLATE utf8_bin NOT NULL COMMENT '灰度发布的配置内容，通常为 JSON 格式',
    `md5` varchar(32) COLLATE utf8_bin DEFAULT NULL COMMENT '配置内容的 MD5 值，用于校验配置的完整性',
    `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录的创建时间',
    `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录的最后修改时间，每次修改时自动更新',
    `src_user` text COLLATE utf8_bin COMMENT '配置项来源用户，用于追踪配置修改的用户',
    `src_ip` varchar(50) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项来源 IP，用于追踪配置修改的来源地址',
    `tenant_id` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户标识，支持多租户模式，可为空字符串表示公共配置',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_configinfo_gray_datagrouptenant` (`data_id`, `group_id`, `tenant_id`) COMMENT '唯一约束，确保同一租户下数据 ID、组 ID 唯一'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='存储灰度发布配置项的表';


CREATE TABLE IF NOT EXISTS `config_info_tag` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '唯一标识每条标签记录',
    `data_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '配置项的唯一标识 ID，用于标识具体配置',
    `group_id` varchar(128) COLLATE utf8_bin NOT NULL COMMENT '配置分组，多个配置项通过此分组区分',
    `tenant_id` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户标识，支持多租户模式，可为空字符串表示公共配置',
    `tag_id` varchar(128) COLLATE utf8_bin NOT NULL COMMENT '标签 ID，用于将配置项与标签进行关联',
    `app_name` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项所属的应用名称',
    `content` longtext COLLATE utf8_bin NOT NULL COMMENT '配置项的内容，通常为 JSON 格式',
    `md5` varchar(32) COLLATE utf8_bin DEFAULT NULL COMMENT '配置内容的 MD5 值，用于校验配置的完整性',
    `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录的创建时间',
    `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录的最后修改时间，每次修改时自动更新',
    `src_user` text COLLATE utf8_bin COMMENT '配置项来源用户，用于追踪配置修改的用户',
    `src_ip` varchar(50) COLLATE utf8_bin DEFAULT NULL COMMENT '配置项来源 IP，用于追踪配置修改的来源地址',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_configinfotag_datagrouptenanttag` (`data_id`, `group_id`, `tenant_id`, `tag_id`) COMMENT '唯一约束，确保同一租户下同一数据 ID、组 ID 和标签 ID 唯一'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='存储配置项与标签关联信息的表';


CREATE TABLE IF NOT EXISTS `config_tags_relation` (
    `id` bigint(20) NOT NULL COMMENT '唯一标识每条标签与配置项的关联记录',
    `tag_name` varchar(128) COLLATE utf8_bin NOT NULL COMMENT '标签名称，用于标识标签',
    `tag_type` varchar(64) COLLATE utf8_bin DEFAULT NULL COMMENT '标签类型，用于区分不同种类的标签',
    `data_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '配置项的唯一标识 ID，关联具体配置',
    `group_id` varchar(128) COLLATE utf8_bin NOT NULL COMMENT '配置分组，多个配置项通过此分组区分',
    `tenant_id` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户标识，支持多租户模式，可为空字符串表示公共配置',
    `nid` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '唯一标识符，每条记录的自增 ID',
    PRIMARY KEY (`nid`),
    UNIQUE KEY `uk_configtagrelation_configidtag` (`id`, `tag_name`, `tag_type`) COMMENT '唯一约束，确保每个配置项与标签的关联唯一',
    KEY `idx_tenant_id` (`tenant_id`) COMMENT '索引租户字段，以提高查询效率'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='配置项与标签关联的表，用于存储配置与标签之间的关系';


CREATE TABLE IF NOT EXISTS `group_capacity` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID，用于唯一标识每条容量记录',
    `group_id` varchar(128) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT 'Group ID，空字符表示整个集群，标识不同的配置组',
    `quota` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '配额，0表示使用默认值，表示允许的最大使用量',
    `usage` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '使用量，表示当前已使用的容量',
    `max_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个配置项的大小上限，单位为字节，0表示使用默认值',
    `max_aggr_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '聚合子配置的最大个数，0表示使用默认值',
    `max_aggr_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个聚合数据的子配置大小上限，单位为字节，0表示使用默认值',
    `max_history_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '最大变更历史数量，限制配置项的历史版本数',
    `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录的创建时间',
    `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录的修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_group_id` (`group_id`) COMMENT '唯一约束，确保每个Group ID在表中的唯一性'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='集群和各Group的容量信息表，存储容量配额和使用情况';


CREATE TABLE IF NOT EXISTS `his_config_info` (
    `id` bigint(64) unsigned NOT NULL COMMENT '主键ID，用于唯一标识每条历史配置记录',
    `nid` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增ID，用于标识每条历史记录',
    `encrypted_data_key` text COLLATE utf8_bin COMMENT '加密数据的密钥，用于存储加密的配置数据',
    `data_id` varchar(255) COLLATE utf8_bin NOT NULL COMMENT '数据ID，用于标识配置数据',
    `group_id` varchar(128) COLLATE utf8_bin NOT NULL COMMENT '分组ID，用于区分不同配置组',
    `app_name` varchar(128) COLLATE utf8_bin DEFAULT NULL COMMENT '应用名称，用于标识应用相关配置',
    `content` longtext COLLATE utf8_bin NOT NULL COMMENT '配置内容，存储实际的配置信息',
    `md5` varchar(32) COLLATE utf8_bin DEFAULT NULL COMMENT '配置内容的MD5值，用于校验数据一致性',
    `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间，记录历史配置创建的时间',
    `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间，记录历史配置的最后修改时间',
    `src_user` text COLLATE utf8_bin COMMENT '源用户，标识进行操作的用户',
    `src_ip` varchar(50) COLLATE utf8_bin DEFAULT NULL COMMENT '源IP，记录进行操作的IP地址',
    `op_type` char(10) COLLATE utf8_bin DEFAULT NULL COMMENT '操作类型，表示此次操作的类型（如新增、修改、删除等）',
    `tenant_id` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户字段，用于区分不同租户的数据',
    `publish_type` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '发布类型，表示配置发布的类型（如正式、灰度等）',
    `gray_name` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '灰度发布名称，用于标识灰度发布的配置',
    `ext_info` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '扩展信息，存储与配置相关的附加信息',
    PRIMARY KEY (`nid`),
    KEY `idx_gmt_create` (`gmt_create`) COMMENT '索引：用于加速基于创建时间的查询',
    KEY `idx_gmt_modified` (`gmt_modified`) COMMENT '索引：用于加速基于修改时间的查询',
    KEY `idx_did` (`data_id`) COMMENT '索引：加速基于数据ID的查询'
    ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='历史配置表，记录每次配置的变更历史，用于多租户改造';


CREATE TABLE IF NOT EXISTS `permissions` (
    `role` varchar(50) NOT NULL COMMENT '角色，表示权限归属的角色',
    `resource` varchar(255) NOT NULL COMMENT '资源，表示该角色拥有权限的资源标识',
    `action` varchar(8) NOT NULL COMMENT '操作，表示角色在资源上可以执行的操作（如查看、修改等）',
    UNIQUE KEY `uk_role_permission` (`role`, `resource`, `action`) USING BTREE COMMENT '唯一约束：角色、资源和操作的组合唯一，确保每个角色对某个资源的操作只有一个权限记录'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='权限表，记录角色、资源和操作的权限信息';


CREATE TABLE IF NOT EXISTS `roles` (
    `username` varchar(50) NOT NULL COMMENT '用户名，标识一个用户',
    `role` varchar(50) NOT NULL COMMENT '角色，标识用户所拥有的角色',
    UNIQUE KEY `idx_user_role` (`username`, `role`) USING BTREE COMMENT '唯一约束：用户名与角色的组合唯一，确保每个用户只能拥有每个角色一次'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户角色表，记录每个用户与其角色的关系';
INSERT INTO roles (username, role) VALUES ('nacos', 'ROLE_ADMIN') ON DUPLICATE KEY UPDATE username='nacos';


CREATE TABLE IF NOT EXISTS `tenant_capacity` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID，用于唯一标识每条记录',
    `tenant_id` varchar(128) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '租户ID，用于唯一标识一个租户',
    `quota` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '租户配额，0表示使用默认配额值',
    `usage` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '当前租户使用的配额量',
    `max_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个配置的最大允许大小（字节），0表示使用默认值',
    `max_aggr_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '每个聚合配置允许的最大子配置数量，0表示使用默认值',
    `max_aggr_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '每个聚合配置允许的最大子配置大小（字节），0表示使用默认值',
    `max_history_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '每个租户最多可保存的历史配置数量',
    `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录的创建时间',
    `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录的修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tenant_id` (`tenant_id`) COMMENT '唯一约束：确保每个租户ID对应一条唯一记录'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='租户容量信息表，用于存储每个租户的配额和配置容量信息';


CREATE TABLE IF NOT EXISTS `tenant_info` (
    `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID，用于唯一标识每条记录',
    `kp` varchar(128) COLLATE utf8_bin NOT NULL COMMENT '关键字，用于唯一标识租户的信息',
    `tenant_id` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户ID，用于唯一标识一个租户',
    `tenant_name` varchar(128) COLLATE utf8_bin DEFAULT '' COMMENT '租户名称',
    `tenant_desc` varchar(256) COLLATE utf8_bin DEFAULT NULL COMMENT '租户描述',
    `create_source` varchar(32) COLLATE utf8_bin DEFAULT NULL COMMENT '租户创建来源',
    `gmt_create` bigint(20) NOT NULL COMMENT '记录的创建时间（时间戳）',
    `gmt_modified` bigint(20) NOT NULL COMMENT '记录的修改时间（时间戳）',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tenant_info_kptenantid` (`kp`,`tenant_id`) COMMENT '唯一约束：确保每个租户和关键字的组合是唯一的',
    KEY `idx_tenant_id` (`tenant_id`) COMMENT '索引：加速基于tenant_id的查询'
    ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='租户信息表，用于存储租户的基本信息，包括ID、名称、描述等';


CREATE TABLE IF NOT EXISTS `users` (
    `username` varchar(50) NOT NULL COMMENT '用户名称，用于唯一标识一个用户',
    `password` varchar(500) NOT NULL COMMENT '用户密码，存储加密后的密码',
    `enabled` tinyint(1) NOT NULL COMMENT '用户是否启用，1表示启用，0表示禁用',
    PRIMARY KEY (`username`) COMMENT '主键：唯一标识每个用户'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='用户信息表，用于存储用户的基本信息，包括用户名、密码及启用状态';
INSERT INTO users (username, password, enabled) VALUES ('nacos', 'nacos', 1) ON DUPLICATE KEY UPDATE username='nacos';
