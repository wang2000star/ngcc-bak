# NGCC 第一轮候选算法及相关官方文件（备份镜像）

国家密码标准研究院 / 商用密码标准研究院（ICCS）官网 <https://www.niccs.org.cn/> 上
**新一代商用密码算法（NGCC）第一轮候选算法**及相关公告文件的备份。

- **候选算法**：119 个官方提交包（公钥密码 84 + 密码杂凑 35），已全部解压入库
- **公告文件**：中英文通知公告 PDF（含提交要求 / 评估准则 / 自评估指引 / 候选名单）+ 通知正文网页 + 栏目存档
- **官方 API 测试包**：3 个
- **仓库内容**：2.86 GiB，84,895 个文件
- **未入库**：全部测试向量（7.16 GiB）—— 见下文第 2 节

---

## 1. 目录结构

```
.
├── 00-manifest/                        清单与校验信息
│   ├── manifest.csv                    官方压缩包清单（含官方 SHA256 与下载地址）
│   ├── manifest-extracted.csv          解压内容清单（算法 → 目录 → 文件数/大小）
│   ├── split-files.csv                 被切片的大文件清单
│   └── 算法清单-Algorithm-Index.md      119 个算法：官网名称 ↔ 官方压缩包名
├── 01-public-key/                      公钥密码算法第一轮候选（84）
│   ├── 01-digital-signature/            数字签名（34）
│   ├── 02-key-encapsulation/            密钥封装（41）
│   └── 03-key-exchange/                 密钥交换（9）
├── 02-hash/                            密码杂凑算法第一轮候选（35）
├── 03-api/                             官方 API 测试包（3）
├── 04-notices/{en,zh}/{pdf,html}/    通知公告 PDF 附件 + 通知正文网页
├── 05-webarchive/                      栏目列表页存档（英文 / 中文）
├── tools/reassemble-large-files.sh     大文件还原脚本
└── README.md
```

每个算法一个目录，目录名即官网压缩包名（去掉 `.zip`），例如
`01-public-key/01-digital-signature/Aigis-Sig+/`、`02-hash/Pavelor/`。

---

## 2. 测试向量未包含在本仓库（重要）

各提交方案自带的测试向量（`Test_Vectors/` 目录、`KAT*.txt`、`*.rsp`）**没有上传**，
原因是它们占了全部内容的约 70%（7.16 GiB），而内容为十六进制文本：

```
实测香农熵 3.95 bit/byte -> 理论压缩上限约 2.0x
git(zlib) 实际压缩比 1.71x   zstd/xz 最好 2.06~2.7x
```

也就是说把这部分放进仓库，付出 70% 的体积只能换来有限的浏览价值。这些文件仍在
**本地完整保留**（未删除、未压缩，保持解压后的原样），需要时可直接使用。

排除规则：
- 路径中任意一级目录名为 `Test_Vectors` 或 `Test_Vector`（不分大小写）
- 扩展名为 `.rsp` 的文件
- 文件名以 `KAT` 开头且扩展名为 `.txt` 的文件

其余内容（源代码、规范书 PDF、知识产权声明、自评估代码与数据、公告文件等）全部入库。

---

## 3. 关于大文件切片

GitHub 拒绝任何超过 **100 MiB** 的单文件。本仓库中仍有 1 个文件超过该限制，
已按 45 MiB 切片：

| 原文件（已切片） | 原始大小 | 分片数 |
|---|---:|---:|
| `02-hash/Pavelor/Pavelor/Basic information and Intellectual property/算法基本信息与知识产权声明（中英文）.pdf` | 201.8 MB | 5 |

**还原方法**（无损，按顺序拼接即可）：

```bash
./tools/reassemble-large-files.sh          # 还原并校验 SHA256，校验后删除分片
./tools/reassemble-large-files.sh --keep   # 还原但保留分片
```

（测试向量中的大文件原本也做了切片，现已改为本地完整保留、不入库。）

---

## 4. 数据来源与校验

所有内容均通过 HTTPS 从 `www.niccs.org.cn` 直接获取，未使用页面中出现的站点内部地址。

- `00-manifest/manifest.csv` 记录每个官方压缩包的**下载地址、大小与 SHA-256**，
  可用于确认下载的原始压缩包与官网一致。
- `00-manifest/manifest-extracted.csv` 记录每个算法解压后的文件数与字节数。
- 原始压缩包在解压前均已通过 `zipfile.testzip()` 完整性校验。

---

## 5. 备注

- 官网算法详情页中的 `Specification`、`IP Statements` 字段目前均为空，网站上并未随
  候选算法发布独立的规范书 / IP 声明文件。
- 公告附件 PDF 已按公告正文中的附件标题重命名（官网原始文件名为随机串），
  原名与官方地址保存在 `00-manifest/manifest.csv`。
- 本仓库是抓取时刻的快照，实时内容请以官网为准。
