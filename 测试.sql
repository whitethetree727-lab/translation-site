-- 查看所有分类及其层级关系（树形结构一目了然）
SELECT category_id, name, parent_id, level, sort_order 
FROM categories 
ORDER BY parent_id, sort_order;

-- 查看管理员账户是否插入成功
SELECT user_id, username, email, role FROM users;