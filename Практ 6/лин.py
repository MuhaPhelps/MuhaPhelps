import pandas as pd
import matplotlib.pyplot as plt


df = pd.read_csv('Terraria.csv')

plt.plot(df.index, df['DPS (SINGLE TARGET)'], marker='o', linestyle='-')

plt.title('Распределение SINGLE TARGET')
plt.xlabel('Name')
plt.ylabel('SINGLE TARGET')
plt.xticks(df.index, df['NAME'], rotation=45)
plt.grid(True)

plt.show()
