# DKEM（PKCKEM-380333）自评估材料包 — 密钥封装（KEM）

依据《新一代商用密码算法 x86 架构 / ARM 架构实现自评估指引》（商用密码标准研究院，2026 年 6 月）整理。
本包为 DKEM 算法的**独立自评估材料**，与 §3.1(1) 电子提交包（will-submit）**平行**提交，不并入电子包。

## 目录结构（指引 §1.4 材料准备）
- `1-Self-Assessment-Reports/`   —— x86 与 ARM 架构的自评估测试报告（中文 + 英文 × {x86, ARM}；提交版为 PDF 共 4 份，完整版另含 docx）
- `2-Algorithm-Source-Code/`   —— 完整算法实现源代码（Reference / Optimized / Additional 实现 + 各实例 build.sh + 实现说明 README）
- `3-Assessment-Code-and-Data/` —— 功能/性能自评估的代码、数据与运行脚本（KAT 向量、run_*.sh、复现说明）
- `依赖说明.md`     —— 第三方库依赖清单与工具链版本

测试日期：2026-06-24。功能 KAT 全部通过；参考实现 ≡ 优化实现（逐字节一致）。

---

# DKEM (PKCKEM-380333) Self-Assessment Materials — Key Encapsulation (KEM)

Prepared per the *Guidelines for Self-Assessment of Cryptographic Algorithms Performance on x86 / ARM Architecture* (Institute of Commercial Cryptography Standards, June 2026).
This package is the **standalone self-assessment material** for DKEM, submitted **in parallel** with the §3.1(1) electronic submission package (`will-submit`); it is not merged into the electronic package.

## Directory structure (Guideline §1.4 Material Preparation)
- `1-Self-Assessment-Reports/`   — Self-assessment test reports for the x86 and ARM architectures (Chinese + English × {x86, ARM}; the submitted version is 4 PDFs, the full version additionally includes docx).
- `2-Algorithm-Source-Code/`   — Complete algorithm implementation source code (Reference / Optimized / Additional implementations + per-instance `build.sh` + an implementation README).
- `3-Assessment-Code-and-Data/` — Code, data and run scripts for the functional / performance self-assessment (KAT vectors, `run_*.sh`, reproduction notes).
- `依赖说明.md`     — Third-party dependency list and toolchain versions (bilingual).

Test date: 2026-06-24. All functional KATs pass; Reference ≡ Optimized (byte-for-byte identical).
