# Rejected Designs and Negative Results

This document records design alternatives that were explored and rejected, with reasons.

## 1. SCL (Successive Cancellation List) Decoder

**Explored:** Using SC-List decoder with list size 8 for better decoding performance.

**Rejected because:**
- Not naturally constant-time (path metrics create timing variability)
- Higher memory requirements (O(L_list * N) storage)
- Marginal improvement over SC for bounded uniform errors
- Sorting operations in list management are side-channel risks

**Status:** SC decoder selected as primary. SCL remains an option for non-constant-time deployments.

## 2. Gaussian Error Distribution

**Explored:** Using discrete Gaussian error instead of bounded uniform.

**Rejected because:**
- Gaussian sampling requires complex constant-time implementation
- Table-based samplers are vulnerable to cache timing attacks
- CDF inversion is computationally expensive
- Bounded uniform achieves sufficient min-entropy with simpler implementation

**Status:** Bounded uniform {−1, 0, +1} selected.

## 3. Construction D' Instead of Construction D

**Explored:** Using Construction D' (congruence-based) instead of Construction D (sum-based).

**Rejected because:**
- For binary polar codes, Constructions D and D' produce equivalent lattices
- Construction D has simpler decoder description
- No security advantage for D' in this setting

**Status:** Construction D selected as primary (D' equivalent).

## 4. Higher Error Bound (B=2)

**Explored:** Using error coordinates in {−2, −1, 0, +1, +2}.

**Rejected because:**
- Increased error norm reduces decoding success probability
- Requires larger decoding radius, increasing BDD attack surface
- Only marginal improvement in min-entropy

**Status:** B=1 selected.

## 5. Reed-Muller Code Lattices (Status Quo)

**Explored:** Keeping Barnes-Wall lattices from Reed-Muller codes as in baseline.

**Rejected because:**
- Polar codes offer better parameter flexibility
- SC decoder has lower complexity than RM decoder
- Polar codes are more hardware-friendly
- Frozen-set design allows fine-grained rate control

**Status:** Polar lattices selected (this is the core innovation).

## 6. Explicit Rejection CCA Transform

**Explored:** Returning failure (⊥) for invalid ciphertexts.

**Rejected because:**
- Provides timing side-channel (failure vs success timing differs)
- Vulnerable to chosen-ciphertext attacks
- Implicit rejection provides same security with better properties

**Status:** Implicit rejection (FO transform) selected.

## 7. SHA-3 Based Extractor (Direct)

**Explored:** Using SHA3-256 directly on error vector as extractor.

**Rejected because:**
- Error vector encoding is not unique (same lattice vector can have different encodings)
- Universal hash extractor provides cleaner security proof
- Two-stage (extractor + KDF) provides better domain separation

**Status:** Universal hash extractor + SHAKE256 KDF selected.

## 8. Public Key Compression via Seeded Generation

**Explored:** Deriving Q_pub from a short seed instead of storing full matrix.

**Rejected because:**
- Seeded generation requires knowing the base lattice structure
- Reveals the generation algorithm might leak information
- Public key size is already acceptable for most applications
- Compression security analysis is complex

**Status:** Full compressed public key format selected.

## 9. Product Lattice Construction

**Explored:** Using product of smaller polar lattices (e.g., Z^8 × Λ_polar).

**Rejected because:**
- Product structure might be detectable
- Automorphism group of product is larger (potential weakness)
- Single polar lattice provides cleaner security analysis

**Status:** Single polar lattice selected.

## 10. LDPC/MDPC Code Lattices

**Explored:** Using LDPC or MDPC codes instead of polar codes.

**Rejected because:**
- LDPC decoders (belief propagation) not naturally constant-time
- MDPC has known structural attacks
- Polar codes provide better theoretical guarantees

**Status:** Polar codes selected.

## Summary Table

| Design | Reason for Rejection | Alternative |
|--------|---------------------|-------------|
| SCL decoder | Not constant-time | SC decoder |
| Gaussian error | Complex sampler | Bounded uniform |
| Construction D' | Equivalent to D | Construction D |
| B=2 | Lower DFP margin | B=1 |
| Barnes-Wall lattice | Less flexible | Polar lattice |
| Explicit rejection | Timing side-channel | Implicit rejection |
| SHA-3 direct | Encoding non-unique | Universal hash + KDF |
| Seeded public key | Security unclear | Full compressed key |
| Product lattice | Detectable structure | Single lattice |
| LDPC codes | Not constant-time | Polar codes |
