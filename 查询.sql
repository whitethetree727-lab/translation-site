-- 切换到我们的数据库
USE `translation_site`;

-- ----------------------------
-- 1. 插入管理员账户（你自己）
-- 注意：密码暂时用明文 'admin123'，后续 FastAPI 阶段我们会用加密算法处理
-- ----------------------------
INSERT INTO `users` (`username`, `password`, `email`, `role`)
VALUES ('admin', 'admin123', '你的邮箱@example.com', 'admin'); 

-- ----------------------------
-- 2. 插入一级大板块（parent_id = NULL）
-- ----------------------------
INSERT INTO `categories` (`name`, `parent_id`, `sort_order`, `level`) 
VALUES 
('棉花糖', NULL, 1, 1),
('付费作品翻译兑换', NULL, 2, 1),
('物料', NULL, 3, 1);

-- ----------------------------
-- 3. 插入“棉花糖”的二级子板块（假设有 3 个匿名提问）
-- 注意：parent_id 要指向“棉花糖”的 category_id（这里应该是 1）
-- ----------------------------
INSERT INTO `categories` (`name`, `parent_id`, `sort_order`, `level`) 
VALUES 
('喜欢的季节', 1, 1, 2),
('喜欢冬季的原因', 1, 2, 2),
('喜欢的香水味', 1, 3, 2);

-- ----------------------------
-- 4. 插入“物料”的二级子板块（角色）
-- ----------------------------
INSERT INTO `categories` (`name`, `parent_id`, `sort_order`, `level`) 
VALUES 
('有马优正', 3, 1, 2),
('濑户内凛太郎', 3, 2, 2);

INSERT INTO `categories` (`name`, `parent_id`, `sort_order`, `level`) 
VALUES 
('第一季特典', 6, 1, 3),
('预热ss', 6, 2, 3);

-- ----------------------------
-- 6. 插入“虎杖悠仁”下的三级子板块
-- parent_id 指向“虎杖悠仁”的 category_id（应该是 7）
-- ----------------------------
INSERT INTO `categories` (`name`, `parent_id`, `sort_order`, `level`) 
VALUES 
('社团脑洞', 7, 1, 3),
('情人节纪念ss', 7, 2, 3);

-- 提示：执行完成后，记下“付费作品翻译兑换”的 category_id（应该是 2），后续插入图片时需要用到它。