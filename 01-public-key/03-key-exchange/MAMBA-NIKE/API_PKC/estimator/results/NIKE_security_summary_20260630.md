# MAMBA-NIKE 安全性估计总结

**生成时间**: 2026-06-30
**模型**: MATZOV (progressive BKZ + AGPS neural-network cost) + ADPS16
**攻击覆盖**: primal (usvp/bdd) + BKW via MATZOV; dual + dual_hybrid via ADPS16
**参数来源**: `parameters.json`（唯一数据源）

---

## 参数概览

| 方案 | 安全级别 | n | q | Δpk | Δu | ηs | ηr |
|------|---------|---|----|-----|----|----|----|
| MAMBA-NIKE-128 | 128 | 1024 | 8192 | 16 | 8 | 2 | 2 |
| MAMBA-NIKE-192 | 192 | 1024 | 8192 | 8 | 8 | 3 | 3 |
| MAMBA-NIKE-256 | 256 | 1024 | 8192 | 8 | 8 | 7 | 7 |
| MAMBA-NIKE-384 | 384 | 2048 | 8192 | 4 | 4 | 2 | 2 |
| MAMBA-NIKE-512 | 512 | 2048 | 8192 | 4 | 4 | 5 | 5 |

---

## 安全性估计结果（汇总）

| 方案 | 目标 | primal | dual | d-hyb | BKW | MATZOV C | MATZOV Q | 裕度 C | 裕度 Q | β | 最佳攻击 |
|------|------|--------|------|-------|-----|----------|----------|--------|--------|----|----------|
| MAMBA-NIKE-128 | 128 | 272.1 | 265.7 | 243.1 | 315.1 | 272.1 | 251.1 | +144.1 | +123.1 | 860 | d-hyb (243.1) |
| MAMBA-NIKE-192 | 192 | 279.3 | 273.3 | 251.5 | 331.6 | 279.3 | 258.4 | +87.3 | +66.4 | 885 | d-hyb (251.5) |
| MAMBA-NIKE-256 | 256 | 294.3 | 289.4 | 283.0 | 367.3 | 294.3 | 273.9 | +38.3 | +17.9 | 938 | d-hyb (283.0) |
| MAMBA-NIKE-384 | 384 | 538.6 | 747.9 | 495.0 | -- | 538.6 | 512.5 | +154.6 | +128.5 | 1755 | d-hyb (495.0) |
| MAMBA-NIKE-512 | 512 | 590.2 | 1119.3 | 571.5 | -- | 590.2 | 512.5 | +78.2 | +0.5 | 1755 | d-hyb (571.5) |

> **列说明**:
> - **MATZOV C** = min(usvp, bdd) under MATZOV（经典安全性估计，log₂ 攻击代价）
> - **MATZOV Q** = 0.292 × β（Core-SVP 经典估计，β 来自 MATZOV primal）
> - **裕度 C/Q** = MATZOV C/Q − 目标安全级别（正值 = 安全，负值 = 不足）
> - primal + BKW 使用 MATZOV 代价模型；dual + d-hyb 使用 ADPS16 模型（MATZOV 不支持 dual）
> - n≥2048 时 BKW 因数值不稳定被跳过（NaN 错误）
> - 误差分布: zero-mean Uniform(−Δ/2, Δ/2)，与精确量化误差方差相同
> - 所有数值均为 log₂(rop)，即攻击所需操作数的对数

---

## 逐方案详细分析

### MAMBA-NIKE-128（目标 128 bit）

| 参数 | 值 |
|------|----|
| n | 1024 |
| q | 8192 |
| Δpk | 16 |
| Δu | 8 |
| ηs | 2 |
| ηr | 2 |

| 攻击类型 | 模型 | log₂(rop) |
|----------|------|-----------|
| primal (bdd) | MATZOV | 272.1 |
| dual | ADPS16 | 265.7 |
| dual_hybrid | ADPS16 | 243.1 |
| BKW | MATZOV | 315.1 |

- **MATZOV β**: 860
- **MATZOV C**: 272.1
- **MATZOV Q**: 251.1
- **最佳攻击**: d-hyb (243.1 bit)
- **安全裕度 (MATZOV C)**: +144.1 bit ✅
- **安全裕度 (MATZOV Q)**: +123.1 bit ✅

---

### MAMBA-NIKE-192（目标 192 bit）

| 参数 | 值 |
|------|----|
| n | 1024 |
| q | 8192 |
| Δpk | 8 |
| Δu | 8 |
| ηs | 3 |
| ηr | 3 |

| 攻击类型 | 模型 | log₂(rop) |
|----------|------|-----------|
| primal (bdd) | MATZOV | 279.3 |
| dual | ADPS16 | 273.3 |
| dual_hybrid | ADPS16 | 251.5 |
| BKW | MATZOV | 331.6 |

- **MATZOV β**: 885
- **MATZOV C**: 279.3
- **MATZOV Q**: 258.4
- **最佳攻击**: d-hyb (251.5 bit)
- **安全裕度 (MATZOV C)**: +87.3 bit ✅
- **安全裕度 (MATZOV Q)**: +66.4 bit ✅

---

### MAMBA-NIKE-256（目标 256 bit）

| 参数 | 值 |
|------|----|
| n | 1024 |
| q | 8192 |
| Δpk | 8 |
| Δu | 8 |
| ηs | 7 |
| ηr | 7 |

| 攻击类型 | 模型 | log₂(rop) |
|----------|------|-----------|
| primal (bdd) | MATZOV | 294.3 |
| dual | ADPS16 | 289.4 |
| dual_hybrid | ADPS16 | 283.0 |
| BKW | MATZOV | 367.3 |

- **MATZOV β**: 938
- **MATZOV C**: 294.3
- **MATZOV Q**: 273.9
- **最佳攻击**: d-hyb (283.0 bit)
- **安全裕度 (MATZOV C)**: +38.3 bit ✅
- **安全裕度 (MATZOV Q)**: +17.9 bit ✅

---

### MAMBA-NIKE-384（目标 384 bit）

| 参数 | 值 |
|------|----|
| n | 2048 |
| q | 8192 |
| Δpk | 4 |
| Δu | 4 |
| ηs | 2 |
| ηr | 2 |

| 攻击类型 | 模型 | log₂(rop) |
|----------|------|-----------|
| primal (bdd) | MATZOV | 538.6 |
| dual | ADPS16 | 747.9 |
| dual_hybrid | ADPS16 | 495.0 |
| BKW | MATZOV | N/A (n≥2048, NaN) |

- **MATZOV β**: 1755
- **MATZOV C**: 538.6
- **MATZOV Q**: 512.5
- **最佳攻击**: d-hyb (495.0 bit)
- **安全裕度 (MATZOV C)**: +154.6 bit ✅
- **安全裕度 (MATZOV Q)**: +128.5 bit ✅

---

### MAMBA-NIKE-512（目标 512 bit）

| 参数 | 值 |
|------|----|
| n | 2048 |
| q | 8192 |
| Δpk | 4 |
| Δu | 4 |
| ηs | 5 |
| ηr | 5 |

| 攻击类型 | 模型 | log₂(rop) |
|----------|------|-----------|
| primal (bdd) | MATZOV | 590.2 |
| dual | ADPS16 | 1119.3 |
| dual_hybrid | ADPS16 | 571.5 |
| BKW | MATZOV | N/A (n≥2048, NaN) |

- **MATZOV β**: 1755
- **MATZOV C**: 590.2
- **MATZOV Q**: 512.5
- **最佳攻击**: d-hyb (571.5 bit)
- **安全裕度 (MATZOV C)**: +78.2 bit ✅
- **安全裕度 (MATZOV Q)**: +0.5 bit ⚠️ (边界)

---

## 结论

### 通过情况

| 方案 | MATZOV C 通过 | MATZOV Q 通过 |
|------|---------------|---------------|
| MAMBA-NIKE-128 | ✅ (+144.1) | ✅ (+123.1) |
| MAMBA-NIKE-192 | ✅ (+87.3) | ✅ (+66.4) |
| MAMBA-NIKE-256 | ✅ (+38.3) | ✅ (+17.9) |
| MAMBA-NIKE-384 | ✅ (+154.6) | ✅ (+128.5) |
| MAMBA-NIKE-512 | ✅ (+78.2) | ⚠️ (+0.5) |

### 关键发现

1. **所有方案 MATZOV C（经典估计）均通过**，安全裕度从 +38.3 bit (NIKE-256) 到 +154.6 bit (NIKE-384)
2. **MATZOV Q（Core-SVP）全部通过**，NIKE-512 裕度 +0.5 bit 较为紧张
3. **dual_hybrid 始终是最强攻击**（所有方案中 d-hyb 给出最优攻击代价）
4. BKW 在所有方案中均远弱于其他攻击（对 n=1024 约 315-367 bit，n≥2048 因数值问题不可用）
5. n=1024 方案安全性由 d-hyb 主导；n=2048 方案的 primal 和 d-hyb 攻击代价均在 495 bit 以上
6. NIKE-384 和 NIKE-512 使用相同的 β=1755（因 n 和 Δ 相同），η 从 2 增加到 5 使 primal 攻击代价从 538.6 升至 590.2，d-hyb 从 495.0 升至 571.5

### 安全裕度排名（MATZOV C）

| 排名 | 方案 | 裕度 |
|------|------|------|
| 1 | MAMBA-NIKE-384 | +154.6 bit |
| 2 | MAMBA-NIKE-128 | +144.1 bit |
| 3 | MAMBA-NIKE-192 | +87.3 bit |
| 4 | MAMBA-NIKE-512 | +78.2 bit |
| 5 | MAMBA-NIKE-256 | +38.3 bit |

---

*报告由安全性估计脚本生成于 2026-06-30*
*参数来源: `parameters.json`*
*代价模型: MATZOV (primal/BKW) + ADPS16 (dual/d-hyb)*
