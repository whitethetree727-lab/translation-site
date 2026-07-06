-- 创建数据库（指定 utf8mb4 以支持中文和emoji）
CREATE DATABASE IF NOT EXISTS translation_site 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE translation_site;

-- ----------------------------
-- 1. 用户表（User）
-- ----------------------------
CREATE TABLE `users` (
  `user_id` INT NOT NULL AUTO_INCREMENT COMMENT '用户编号',
  `username` VARCHAR(50) NOT NULL COMMENT '用户名',
  `password` VARCHAR(255) NOT NULL COMMENT '登录密码（加密存储）',
  `email` VARCHAR(100) NOT NULL COMMENT '电子邮箱（登录账号）',
  `role` ENUM('admin', 'user') NOT NULL DEFAULT 'user' COMMENT '用户角色：admin=管理员，user=普通访客',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像地址',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ----------------------------
-- 2. 分类/板块表（Category）—— 自关联树形结构
-- ----------------------------
CREATE TABLE `categories` (
  `category_id` INT NOT NULL AUTO_INCREMENT COMMENT '分类编号',
  `name` VARCHAR(100) NOT NULL COMMENT '分类名称（如：物料、五条悟）',
  `parent_id` INT DEFAULT NULL COMMENT '父级分类编号（NULL表示一级大板块）',
  `sort_order` INT DEFAULT 0 COMMENT '排序序号（同一父级下的顺序）',
  `level` TINYINT DEFAULT 1 COMMENT '层级深度（1=一级，2=二级，3=三级）',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`category_id`),
  KEY `idx_parent_id` (`parent_id`),
  CONSTRAINT `fk_category_parent` FOREIGN KEY (`parent_id`) 
    REFERENCES `categories` (`category_id`) 
    ON DELETE CASCADE  -- 若父级删除，子级一并删除
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分类/板块表（自关联实现无限级嵌套）';

-- ----------------------------
-- 3. 标签表（Tag）—— 给图片打标记
-- ----------------------------
CREATE TABLE `tags` (
  `tag_id` INT NOT NULL AUTO_INCREMENT COMMENT '标签编号',
  `tag_name` VARCHAR(50) NOT NULL COMMENT '标签名称（如：已校对）',
  `color` VARCHAR(20) DEFAULT NULL COMMENT '标签颜色（前端用，如 #FF0000）',
  PRIMARY KEY (`tag_id`),
  UNIQUE KEY `uk_tag_name` (`tag_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='标签表';

-- ----------------------------
-- 4. 图片作品表（ImageWork）—— 所有翻译图片
-- ----------------------------
CREATE TABLE `image_works` (
  `image_id` INT NOT NULL AUTO_INCREMENT COMMENT '图片编号',
  `category_id` INT NOT NULL COMMENT '所属分类编号（必须指向最末级子分类）',
  `user_id` INT NOT NULL COMMENT '上传用户编号（固定指向管理员）',
  `image_url` VARCHAR(255) NOT NULL COMMENT '图片存储路径',
  `original_source` VARCHAR(200) DEFAULT NULL COMMENT '图片来源说明（如：推特匿名提问）',
  `translation_note` TEXT COMMENT '翻译备注/说明',
  `uploaded_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  PRIMARY KEY (`image_id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `fk_image_category` FOREIGN KEY (`category_id`) 
    REFERENCES `categories` (`category_id`) 
    ON DELETE CASCADE  -- 若子分类删除，其下图片一并删除
    ON UPDATE CASCADE,
  CONSTRAINT `fk_image_user` FOREIGN KEY (`user_id`) 
    REFERENCES `users` (`user_id`) 
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图片作品表';

-- ----------------------------
-- 5. 图片-标签关联表（ImageTag）—— 多对多中间表
-- ----------------------------
CREATE TABLE `image_tags` (
  `image_id` INT NOT NULL COMMENT '图片编号',
  `tag_id` INT NOT NULL COMMENT '标签编号',
  PRIMARY KEY (`image_id`, `tag_id`),  -- 联合主键，避免重复关联
  KEY `idx_tag_id` (`tag_id`),
  CONSTRAINT `fk_imagetag_image` FOREIGN KEY (`image_id`) 
    REFERENCES `image_works` (`image_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_imagetag_tag` FOREIGN KEY (`tag_id`) 
    REFERENCES `tags` (`tag_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图片-标签关联表';

-- ----------------------------
-- 6. 评论表（Comment）—— 普通用户留言
-- ----------------------------
CREATE TABLE `comments` (
  `comment_id` INT NOT NULL AUTO_INCREMENT COMMENT '评论编号',
  `image_id` INT NOT NULL COMMENT '所属图片编号',
  `user_id` INT NOT NULL COMMENT '评论人编号',
  `content` TEXT NOT NULL COMMENT '评论内容',
  `parent_comment_id` INT DEFAULT NULL COMMENT '父级评论编号（NULL表示一级评论）',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '评论时间',
  PRIMARY KEY (`comment_id`),
  KEY `idx_image_id` (`image_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_parent_id` (`parent_comment_id`),
  CONSTRAINT `fk_comment_image` FOREIGN KEY (`image_id`) 
    REFERENCES `image_works` (`image_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comment_user` FOREIGN KEY (`user_id`) 
    REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comment_parent` FOREIGN KEY (`parent_comment_id`) 
    REFERENCES `comments` (`comment_id`) ON DELETE CASCADE  -- 父评论删除，所有回复一并删除
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评论表（支持楼中楼回复）';

-- ----------------------------
-- 7. 兑换记录表（Redemption）—— 付费作品兑换（含隐私邮箱）
-- ----------------------------
CREATE TABLE `redemptions` (
  `redemption_id` INT NOT NULL AUTO_INCREMENT COMMENT '兑换记录编号',
  `user_id` INT NOT NULL COMMENT '申请人编号',
  `image_id` INT NOT NULL COMMENT '兑换的图片编号（必须属于“付费作品翻译兑换”板块）',
  `contact_email` VARCHAR(100) NOT NULL COMMENT '联系邮箱（用户接收翻译文件，仅管理员可见）',
  `status` ENUM('pending', 'completed', 'cancelled') NOT NULL DEFAULT 'pending' COMMENT '兑换状态：待处理/已完成/已取消',
  `note` TEXT COMMENT '管理员备注（普通用户不可见）',
  `applied_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `processed_at` DATETIME DEFAULT NULL COMMENT '处理时间（状态变为 completed 时记录）',
  PRIMARY KEY (`redemption_id`),
  UNIQUE KEY `uk_user_image` (`user_id`, `image_id`) COMMENT '一个用户对同一张付费图片只能申请一次兑换',
  KEY `idx_image_id` (`image_id`),
  CONSTRAINT `fk_redemption_user` FOREIGN KEY (`user_id`) 
    REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_redemption_image` FOREIGN KEY (`image_id`) 
    REFERENCES `image_works` (`image_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='兑换记录表';