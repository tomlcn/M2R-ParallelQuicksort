#!/usr/bin/env bash

OUTPUT_DIRECTORY="data/$(hostname)_$(date +%F)"
mkdir -p "$OUTPUT_DIRECTORY"
TIMESTAMP="$(date +%R | tr ':' '-')"

echo "All Benchmarks"

echo "[1/4] Benchmark Original..."
FILE_ORIG="$OUTPUT_DIRECTORY/measurements_original_$TIMESTAMP.txt"
touch "$FILE_ORIG"
for i in 100 1000 10000 100000 1000000 10000000; do
    for rep in $(seq 1 5); do
        echo "Size: $i" >> "$FILE_ORIG"
        ./src/parallelQuicksort "$i" >> "$FILE_ORIG"
    done
done

echo "[2/4] Benchmark with more size"
FILE_SIZE="$OUTPUT_DIRECTORY/measurements_size_$TIMESTAMP.txt"
touch "$FILE_SIZE"
for i in 100 300 1000 3000 10000 30000 100000 300000 1000000 10000000 30000000; do
    for rep in $(seq 1 5); do
        echo "Size: $i" >> "$FILE_SIZE"
        ./src/parallelQuicksort "$i" >> "$FILE_SIZE"
    done
done

echo "[3/4] Benchmark with more reps."
FILE_REPS="$OUTPUT_DIRECTORY/measurements_reps_$TIMESTAMP.txt"
touch "$FILE_REPS"
for i in 100 1000 10000 100000 1000000 10000000 30000000; do
    for rep in $(seq 1 30); do
        echo "Size: $i" >> "$FILE_REPS"
        ./src/parallelQuicksort "$i" >> "$FILE_REPS"
    done
done

echo "[4/4] Benchmark randomized input."
FILE_RAND="$OUTPUT_DIRECTORY/measurements_random_$TIMESTAMP.txt"
touch "$FILE_RAND"
for i in 100 1000 10000 100000 1000000 10000000 30000000; do
    for rep in $(seq 1 5); do
        echo "$i"
    done
done | shuf | while read -r i; do
    echo "Size: $i" >> "$FILE_RAND"
    ./src/parallelQuicksort "$i" >> "$FILE_RAND"
done