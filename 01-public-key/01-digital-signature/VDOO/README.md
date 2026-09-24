# VDOO (Vinegar-Diagonal-Oil-Oil)
An implementation in C of VDOO, a multivariate signature scheme

## Building the Binaries
We can build the binaries using the CMakeFiles.txt in the folder `./Reference_Implementaion` or `./Optimized_Implementation`

### Building only the VDOO binaries

Use the provided `CMakeFiles.txt` on the wanted folder (`/vdoo_128`, `/vdoo_256` or `/vdoo_512`) :

```bash
mkdir build
cd build
cmake ..
make vdoo_bins
```

After a successful build, the following executables are created:

- `vdoo-keygen`
- `vdoo-sign`
- `vdoo-verif`

### Building the binary to generate onnly the KAT gnerator

Just need to add `KAT_SIG`:

```bash
mkdir build
cd build
cmake ..
make KAT_SIG
```

After a successful build, the following executable is created:

`KAT_SIG`

### Building the binary to generate onnly speed benchmark

Just need to add `KAT_SIG`:

```bash
mkdir build
cd build
cmake ..
make bench_speed
```

After a successful build, the following executable is created:

`bench_speed`


## Usage
### Key Generation
Generates a key pair (public key and private key)

```bash
./vdoo-genkey pk_file_name sk_file_name [random_seed_file]
```

Example:

```bash
./vdoo-keygen public.key secret.key
```

### Signature
Sign a message using the secret key:

```bash
./vdoo-sign sk_file_name file_to_be_signed
```

Example:

```bash
./vdoo-sign secret.key message.txt > signature.sig
```

### Verification
Verify a signature using the public key:

```bash
./vdoo-verif pk_file_name signature_file_name message_file_name
```

Example:

```bash
./vdoo-verif public.key signature.sig message.txt
```

### KAT generation
Generate the test vectors:

```bash
./KAT_SIG
```

### Speed benchmark
Do the speed benchmark:

```bash
./bench_speed
```