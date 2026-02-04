
# MkDocs 搭建笔记

## 1. 核心命令

* **安装工具**：`pip install mkdocs`

选择一个文件夹 然后在cmd里面输入
* **新建项目**：`mkdocs new my_tree_hole` （或者在当前目录用 `mkdocs new .`）
新的文件夹目录下面
* **启动网站**：`mkdocs serve` （这一步叫“本地预览”，关掉黑框网页就没了）

## 2. 如何修改内容

* **改文章**：修改 `docs/index.md` 文件（记事本打开，写什么显示什么）。

* **改网站名**：修改 `mkdocs.yml` 文件，找到 `site_name` 修改。



## 3. 如何🔗到互联网
第一次发布 (连接 GitHub)
(只需要做一次)

在 GitHub 网页上新建一个 Public 仓库。

在本地cmd里依次输入：

git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/你的ID/仓库名.git
mkdocs gh-deploy


日常更新 (改 -> 发 -> 看)
(以后每次写日记只做这一步)

改：在本地改好 .md 文件并保存。

发：打开黑框框（确保在项目文件夹里），输入：

Bash
mkdocs gh-deploy
看：等几十秒，刷新你的专属网址。

4. 常见报错速查
mkdocs.yml does not exist -> 你忘了 cd 进文件夹！

No such command 'server' -> 拼写错了，是 serve。

Permission denied / 卡住不动 -> 网络卡了，Ctrl+C 关掉重试。