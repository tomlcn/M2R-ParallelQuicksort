import glob
import os

txt_files = glob.glob("data/tom6/*.txt")

for txt_file in txt_files:
    csv_file = txt_file.replace(".txt", ".csv")
    data = []
    current_size = None
    
    with open(txt_file, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if line.startswith("Size:"):
                try:
                    current_size = int(line.split(":")[1].strip())
                except ValueError:
                    pass
            elif "quicksort took:" in line and current_size is not None:
                parts = line.split("quicksort took:")
                algo = parts[0].strip()
                try:
                    time_val = float(parts[1].replace("sec.", "").strip())
                    data.append((current_size, algo, time_val))
                except ValueError:
                    pass
                    
    with open(csv_file, 'w', encoding='utf-8') as f:
        f.write("size,algo,time\n")
        for size, algo, time_val in data:
            f.write(f"{size},\"{algo}\",{time_val}\n")
            