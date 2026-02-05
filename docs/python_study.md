# OCR

这套代码的核心在于将“**非结构化数据**”（图片里的像素）转化为“**结构化数据**”（文件名、Excel表格内容等）。掌握了这个逻辑，你以后可以用它来批量处理发票、身份证、车牌，甚至自动录入纸质表格。

---

## 1. 核心流程图解 (Logic Flow)

代码的运行逻辑可以拆解为四个步骤：

1. **加载 (Load):** Python 读取图片文件。
2. **识别 (See):** OCR 模型（cnocr）扫描图片，把“像素”翻译成“文字列表”。
3. **提取 (Think):** 使用正则表达式（Regex）在杂乱的文字中“抠”出你想要的关键信息（如编码、名称）。
4. **执行 (Act):** 根据提取到的信息，执行操作（重命名文件、写入数据库等）。

---

### 2. 代码深度拆解 (Code Breakdown)

代码通用模组

#### 库安装
在终端（CMD）运行以下命令：
```
Bash
pip install cnocr -i https://pypi.org/simple
```

#### 模块一：环境与模型加载

这是“准备工作”。`cnocr` 是一个预训练好的深度学习模型，它已经“看过”数百万个汉字，所以不需要你重新训练，拿来就能用。

```python
from cnocr import CnOcr  # 导入识别工具

# 初始化模型
# 这一步会加载神经网络权重到内存中。
# 如果你有显卡(GPU)，它会自动使用；没有则用CPU。
ocr = CnOcr() 

```

#### 模块二：核心识别 (The "Eyes")


```python
# 传入图片路径，返回识别结果
result = ocr.ocr(file_path)

# result 的长相通常是这样的列表（List of Dictionaries）：
# [
#    {'text': '中国能建', 'score': 0.98}, 
#    {'text': '资产编码: 101104...', 'score': 0.99},
#    ...
# ]

```

* **迁移思路**：如果要识别英文，可以换成

``ocr = CnOcr(det_model_name='en_..._det', rec_model_name='en_..._rec')` 或者换用 `EasyOCR` 库。

#### 模块三：信息清洗 (The "Brain")

OCR 识别出来的字是杂乱的，**正则表达式 (Regular Expression / Regex)** 是这里的灵魂。它像一个过滤器，只保留符合规则的文字。

````python
import re

def extract_info(ocr_result):
    for item in ocr_result:
        text = item['text']
        
        # 🎯 核心技巧：正则匹配
        # 解释：r"..." 是正则语法
        # (?:编码|编号)  -> 找“编码”或者“编号”这两个词
        # [:：\s]* -> 允许后面跟着冒号(中英文皆可)或空格
        # ([1]\d{13})    -> 关键！抓取以1开头，后面跟13个数字的串
        code_match = re.search(r"(?:编码|编号)[:：\s]*([1]\d{13})", text)
        
        if code_match:
            return code_match.group(1) # 返回抓到的那串数字

````

* **迁移思路**：
* **车牌**：把正则改成匹配 `[京津沪...][A-Z]...`
* **金额**：把正则改成匹配 `￥\d+\.\d+`
* **手机号**：把正则改成匹配 `1[3-9]\d{9}`



---

### 3. 如何迁移到其他项目？(Migration Guide)

学会了这个模块，你可以把它应用到各种场景。以下是三个常见的迁移方向：

#### 场景 A：从“重命名”改为“录入 Excel”

老板让你把 100 张资产标签图片的信息统计到一个 Excel 表格里，而不是改文件名。

**修改方案**：
保留 `ocr.ocr` 和 `extract_info`，把最后的 `os.rename` 换成 `pandas`。

```python
import pandas as pd

# 1. 准备一个空列表存数据
data_list = []

for filename in files:
    # ... (前面的识别步骤一样) ...
    code, name = extract_info(result)
    
    if code != "UNK":
        # 2. 不改名，而是存入列表
        data_list.append({
            "文件名": filename,
            "资产编码": code,
            "设备名称": name
        })

# 3. 循环结束后，一次性写入 Excel
df = pd.DataFrame(data_list)
df.to_excel("资产统计表.xlsx", index=False)
print("Excel 生成完毕！")

```

#### 场景 B：识别不同类型的单据（如发票）

你想识别发票上的“发票代码”和“开票日期”。

**修改方案**：
只需要修改 `extract_info` 函数里的正则表达式。

```python
def extract_invoice_info(text):
    # 找发票代码 (通常是10或12位数字)
    code = re.search(r"发票代码[:：\s]*(\d{10,12})", text)
    
    # 找日期 (例如 2024年05月01日)
    date = re.search(r"(\d{4}年\d{2}月\d{2}日)", text)
    
    return code, date

```

#### 场景 C：做成一个小工具 (GUI)

你想做一个像软件一样的窗口，拖进去图片就能识别。

**修改方案**：
你需要引入 `tkinter` 或 `PyQt` 库来画界面，点击“开始”按钮时，触发上面的 `process_images()` 函数。

---

### 4. 总结笔记

如果你要在笔记本上记下来，只需记住这三个核心点：

1. **输入端**：`cnocr` 对中文支持最好，安装简单（适合 Python 3.12）。
2. **处理端**：**正则表达式**是数据提取的核心技能。OCR 只是把图片变文字，正则才是把文字变数据的关键。
3. **输出端**：数据拿到手后，是`重命名(os.rename)`，还是`存表格(pandas)`，还是`存数据库(sqlite)`，完全看你的业务需求。