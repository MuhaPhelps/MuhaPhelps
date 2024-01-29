
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('Terraria.csv')


plt.figure(figsize=(8, 6))
plt.scatter(df['DPS (SINGLE TARGET)'], df['NAME'], alpha=0.8, edgecolors='w')

plt.title('Диаграмма рассеивания: ')
plt.xlabel('DPS (SINGLE TARGET)')
plt.ylabel('NAME')
plt.grid(True)
plt.show()
