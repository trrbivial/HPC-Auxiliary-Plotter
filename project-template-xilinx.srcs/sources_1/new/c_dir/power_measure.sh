# 记录开始能量
start=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

# 启动程序
./a.out

# 记录结束能量
end=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

# 计算总耗能（焦耳）与平均功率（假设程序运行 t 秒）
energy_joule=$((end - start))  # 单位微焦耳
time=1.309  # 假设程序运行 3.5 秒
echo "平均功耗约为 $(echo "$energy_joule / 1000000 / $time" | bc -l) W"
