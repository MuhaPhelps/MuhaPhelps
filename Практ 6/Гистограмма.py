import pandas as pd
import matplotlib.pyplot as plt



df = pd.read_csv('Terraria.csv')


plt.figure(figsize=(8, 6))
plt.hist(df['DPS (SINGLE TARGET)'], bins=10, color='skyblue', edgecolor='black')


plt.title('Гистограмма ')
plt.xlabel('DPS (SINGLE TARGET)')
plt.ylabel('Частоста')
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.show()
