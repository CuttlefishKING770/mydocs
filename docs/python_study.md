# python 学习模块
## 1.OCR (Optical Character Recognition，光学字符识别)
    学习中最常用的“第一步”是调用成熟的**开源引擎**（如 Tesseract）并配合**图像处理**（OpenCV）。
---

### 1.1 核心逻辑：OCR 的流水线
OCR 不是一个简单的函数，它是一套流程：  
**输入** ：一张图片。    
**预处理（关键）**：把图片弄干净（去噪、变黑白），让机器看得清。    
**识别**：调用 OCR 引擎把像素变成文字。 
**输出**：文本字符串。  
---
### 1.2 工具选型：教具 vs 武器
Tesseract (Google)：

特点：老牌、轻量，依赖传统的像素比对。  
缺点：对抗干扰能力弱（如金属反光、噪点），需要极复杂的 OpenCV 预处理（旋转、降噪、腐蚀膨胀）才能凑合用。    
定位：适合学习原理，不适合复杂背景。

PaddleOCR (Baidu):  
特点：基于深度学习，自带“人眼”般的纠错能力。    
优势：自动纠正方向（横/竖/倒立）、自动忽略背景噪点、中文识别率极高。
定位：工业级生产力工具，推荐直接使用。


### 1.3 环境配置：安装环境十分麻烦
Python 开发中最难的往往不是代码，而是环境依赖冲突。
安装命令：

#### 1. 清理环境
```bash title="cmd"
pip uninstall paddleocr paddlex modelscope -y
```
####  2. 安装稳健版引擎
```bash title="cmd"
python -m pip install "paddlepaddle==2.6.2" -i https://pypi.tuna.tsinghua.edu.cn/simple --force-reinstall
```
####  3. 安装工具库
```bash title="cmd"
pip install "paddleocr==2.7.3" -i https://pypi.tuna.tsinghua.edu.cn/simple
```
####  4. 降级数学库
```bash title="cmd"
pip install "numpy<2.0" -i https://pypi.tuna.tsinghua.edu.cn/simple --force-reinstall
```
### 1.4 代码迁移：批量识别与重命名核心闭环

**核心目标**：实现 `OCR 读取图片` -> `正则提取关键信息` -> `文件改名` 的自动化闭环。

#### 1. 关键设置 (系统熔断开关)

**注意**：在 `import` 任何深度学习库（如 PaddleOCR）之前，必须**优先**执行以下代码。防止 Intel 的 MKLDNN 加速库与 OCR 引擎发生冲突，导致程序直接崩溃 (Flash 闪退)。

```bash title="python"
import os

# 1. 强制使用 CPU 模式，且彻底关闭 Intel 加速器
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["FLAGS_enable_mkldnn"] = "0"

# 2. 禁用 GPU (如果是服务器环境不想占显存)
os.environ["CUDA_VISIBLE_DEVICES"] = "" 

import re # 导入正则库
```
#### 2 数据提取 (Regex 正则策略)
OCR 识别出的原始文本通常包含杂音，我们需要针对不同场景定制“筛子”：

场景 A (变长编码)：如资产编号。r'\d{12,}' (连续 12 位以上)

场景 B (定长编码)：如邮编。r'\d{6}' (精准 6 位)

场景 C (特定规则)：如手机号。r'1\d{10}' (1 开头后跟 10 位)  

````Pbash title="python"
text = "联系电话: 13800138000 (内部)"

# 场景 D：提取手机号
match = re.search(r'1\d{10}', text)

if match:
    print(f"找到手机号: {match.group()}")
else:
    print("未找到匹配项")
````
#### 3. 数据清洗 (多维手段)

OCR 的结果往往包含误读字符、多余换行或混乱的标点。我们根据脏数据的程度，选择不同的清洗策略。

##### 3.1 基础物理清洗 (String 原生方法)
**适用场景**：固定格式的微调，无需动用正则，速度最快。

* `strip()`: 去除首尾的“幽灵字符”（空格、换行符 `\n`）。
* `replace()`: 简单的定点替换（比如把中文冒号换成英文）。
* `split()`: 掐头去尾，只取中间。

````python title="清洗"
text = "  型号：Dell-7000 \n"

# 1. 去除首尾空白 (常用起手式)
clean_s = text.strip() 
# 结果: "型号：Dell-7000"

# 2. 统一符号 (把中文冒号改成英文，便于后续处理)
clean_s = clean_s.replace("：", ":")
# 结果: "型号:Dell-7000"

# 3. 切割提取 (只想要冒号后面的内容)
# split返回的是列表，[-1] 取最后一部分
final_data = clean_s.split(":")[-1]
# 结果: "Dell-7000"
````
##### 3.2 外科手术式清洗 (RegEx 正则替换)    
适用场景：规律性的杂质，比如删除括号内的备注、去掉所有标点、合并多余空格。
re.sub(pattern, replacement, string)：核心函数。

````python title="正则"
import re

text = "规  格 : Dell-7000 (保修期/3年) [库存:10]"

# --- 案例 A：去除所有括号及括号内的内容 ---
# \(.*?\) 匹配小括号, \[.*?\] 匹配中括号
# ? 表示非贪婪模式，遇到第一个反括号就停，防止误删中间所有内容
no_bracket = re.sub(r'\(.*?\)|\[.*?\]', '', text)
# 结果: "规  格 : Dell-7000  "

# --- 案例 B：清理 OCR 常见的“文字炸裂” (合并多余空格) ---
# \s+ 表示匹配一个或多个连续空格，统一替换为一个空格
fix_space = re.sub(r'\s+', ' ', text)
# 结果: "规 格 : Dell-7000 (保修期/3年) [库存:10]"

# --- 案例 C：只保留数字和字母 (暴力清洗) ---
# [^...] 表示“除了这些以外的”，全部替换为空
only_code = re.sub(r'[^a-zA-Z0-9-]', '', "ID: A-123 (v2)")
# 结果: "A-123v2" (连冒号和括号都没了，慎用)
````
##### 3.3 OCR 专属降噪技巧 (针对性修复)
适用场景：解决 OCR 容易把 1 读成 l，把 0 读成 O，或者把完整单词拆开的“老毛病”。

````python title="降噪"
raw_ocr = "S0ny 2O24  Cam era" # 典型 OCR 翻车现场

# 1. 易混淆字符修正 (构建映射表)
# 把 'O' 修正为 '0', 把 'l' 修正为 '1' (视具体业务而定)
fix_char = raw_ocr.replace('O', '0').replace('l', '1')

# 2. 修复单词内部断裂 (英文 OCR 常见痛点)
# 逻辑：如果两个字母中间只夹了一个空格，很可能是误断
# (Look-behind/ahead 断言) 查找 "字母 空格 字母" 的结构，并删掉空格
# (?<=[a-zA-Z]) 检查前面是字母, (?=[a-zA-Z]) 检查后面是字母
fix_word = re.sub(r'(?<=[a-zA-Z])\s(?=[a-zA-Z])', '', raw_ocr)

# 结果对比：
# 原文: "S0ny 2O24  Cam era"
# 修正: "S0ny 2024  Camera"
````

#### 1.5 核心实战：唤醒 PaddleOCR 引擎
这是整个流程的“心脏”。我们需要加载模型，并把图片喂进去。

代码实现
````Python
from paddleocr import PaddleOCR

# --- 1. 初始化引擎 (只做一次) ---
# lang="ch": 支持中英文通用
# use_angle_cls=True: 自动纠正图片方向 (比如手机拍歪了，它能自动转正，强烈建议开启)
# show_log=False: 关掉烦人的进度条日志
ocr = PaddleOCR(use_angle_cls=True, lang="ch", show_log=False) 

# --- 2. 执行识别 ---
img_path = 'test_image.jpg'
# 这一步会下载模型（约 15MB），首次运行需要联网
result = ocr.ocr(img_path, cls=True)
````
💡 避坑指南：模型下载卡住怎么办？
PaddleOCR 首次运行时会自动下载模型文件到 ~/.paddleocr/ 目录。

现象：程序卡在 Namespace... 不动，或者报错连接超时。

解法：这是因为国内网络连接 GitHub/Baidu 偶尔抽风。建议手动去官网下载“轻量级中文推理模型”，解压后放在项目目录下，通过 det_model_dir 和 rec_model_dir 参数指定路径。

#### 1.6 数据解剖：理解 OCR 的返回值
PaddleOCR 的返回值结构非常“洋葱”（层层包裹），新手最容易在这里栽跟头。

返回值结构图解
它是一个列表的列表的列表。

````python title="返回值"
# result 的样子 (假设识别了一行字 "姓名: 张三")
[
  [  # 第一层：整张图片的结果
     [ # 第一行文字的数据
        [[10, 10], [100, 10], [100, 50], [10, 50]],  # 0. 坐标 (左上, 右上, 右下, 左下)
        ('姓名: 张三', 0.99)                         # 1. 内容与置信度 (Tuple)
     ]
  ]
]
````
提取实战：只拿文字
通常我们要的只是文字内容，不需要坐标和置信度。

````python title="遍历解构"
# 判空保护：如果图片全是白的，result 可能为 None 或空列表
if not result or not result[0]:
    print("未识别到文字")
else:
    # 遍历每一行识别结果
    for line in result[0]:
        # line[1] 是 ('文本', 置信度)
        # line[1][0] 才是纯文本
        text_content = line[1][0] 
        print(f"识别内容: {text_content}")
    
        # 结合之前的正则清洗 (举例)
        # clean_text = re.sub(..., text_content)
````   