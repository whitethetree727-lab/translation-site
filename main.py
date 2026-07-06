from fastapi import FastAPI, File, UploadFile, Form, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
import shutil
from datetime import datetime

app = FastAPI(title="翻译内容管理 API")

# 1. 允许所有来源访问（开发环境）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. 数据库配置（记得改密码）
DATABASE_URL = "mysql+pymysql://root:yunyun37@localhost:3306/translation_site?charset=utf8mb4"
engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(bind=engine)

# 3. 创建上传文件夹（如果不存在）
UPLOAD_DIR = "uploads"
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

# --- 临时登录验证（先硬编码，后续会换JWT）---
ADMIN_PASSWORD = "admin123"  # 暂时写死，方便测试

@app.post("/api/login")
async def login(password: str = Form(...)):
    if password == ADMIN_PASSWORD:
        return {"success": True, "message": "登录成功", "role": "admin"}
    else:
        raise HTTPException(status_code=401, detail="密码错误")

# --- 图片上传接口 ---
@app.post("/api/upload")
async def upload_image(
    file: UploadFile = File(...),
    category_id: int = Form(...),
    translation_note: str = Form(None),
    original_source: str = Form(None)
):
    # 1. 生成保存路径（按日期分文件夹）
    date_str = datetime.now().strftime("%Y/%m")
    save_dir = os.path.join(UPLOAD_DIR, date_str)
    if not os.path.exists(save_dir):
        os.makedirs(save_dir)
    
    # 生成唯一文件名
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_extension = os.path.splitext(file.filename)[1]
    save_path = os.path.join(save_dir, f"{timestamp}_{file.filename}")
    
    # 2. 保存文件到本地
    with open(save_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # 3. 存入数据库（默认管理员 user_id = 1）
    db_path = save_path.replace("\\", "/")  # 统一路径格式
    with SessionLocal() as session:
        # 注意：这里暂时写死 user_id=1（你自己），确保你的 users 表里有 id=1 的记录
        sql = text("""
            INSERT INTO image_works 
            (category_id, user_id, image_url, original_source, translation_note, uploaded_at)
            VALUES (:cat, 1, :url, :src, :note, NOW())
        """)
        session.execute(sql, {"cat": category_id, "url": db_path, "src": original_source, "note": translation_note})
        session.commit()
    
    return {"message": "上传成功", "filename": file.filename, "path": db_path}

# --- 原有接口保持不变（根路径、分类列表等）---
@app.get("/")
async def root():
    return {"message": "翻译网站 API 服务运行正常"}

@app.get("/api/categories/root")
async def get_root_categories():
    with SessionLocal() as session:
        result = session.execute(
            text("SELECT category_id, name, sort_order, level FROM categories WHERE parent_id IS NULL ORDER BY sort_order")
        )
        categories = result.mappings().all()
        return {"data": categories}
    
@app.get("/api/categories/{parent_id}/children")
async def get_children(parent_id: int):
    with SessionLocal() as session:
        result = session.execute(
            text("SELECT category_id, name, sort_order, level FROM categories WHERE parent_id = :pid ORDER BY sort_order"),
            {"pid": parent_id}
        )
        children = result.mappings().all()
        return {"data": children}