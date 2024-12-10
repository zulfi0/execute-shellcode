raw_shellcode_path = "/home/user/Documents/local.bin"

with open(raw_shellcode_path, "rb") as f:
    raw_shellcode = f.read()

ps = ",".join(f"0x{byte:02x}" for byte in raw_shellcode)
print(ps)
